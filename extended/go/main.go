// go (gin): a Gin web app with optional SQL database support.
// Dependencies are vendored (see vendor/) so the image builds fully offline -
// no Go module proxy or mirror is required (GOPROXY=off, -mod=vendor).
//
// Database is optional and driven by the DATABASE_URL environment variable
// injected by the platform (mysql://... or postgresql://...). If unset, the app
// runs without a database.
package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
)

// openDB opens the database described by DATABASE_URL, returning the handle and
// the resolved engine name ("none" when no DATABASE_URL is set).
func openDB() (*sql.DB, string) {
	raw := os.Getenv("DATABASE_URL")
	if raw == "" {
		return nil, "none"
	}
	u, err := url.Parse(raw)
	if err != nil {
		log.Printf("invalid DATABASE_URL: %v", err)
		return nil, "error"
	}
	switch u.Scheme {
	case "postgres", "postgresql":
		// The internal Postgres has no TLS; default sslmode=disable if the URL
		// does not already specify it.
		if !strings.Contains(raw, "sslmode=") {
			if u.RawQuery == "" {
				raw += "?sslmode=disable"
			} else {
				raw += "&sslmode=disable"
			}
		}
		db, err := sql.Open("postgres", raw)
		if err != nil {
			log.Printf("postgres open error: %v", err)
			return nil, "error"
		}
		return db, "postgres"
	case "mysql":
		// go-sql-driver DSN form: user:pass@tcp(host:port)/dbname
		pw, _ := u.User.Password()
		dbname := strings.TrimPrefix(u.Path, "/")
		dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s", u.User.Username(), pw, u.Host, dbname)
		db, err := sql.Open("mysql", dsn)
		if err != nil {
			log.Printf("mysql open error: %v", err)
			return nil, "error"
		}
		return db, "mysql"
	}
	return nil, "unsupported"
}

func main() {
	db, engine := openDB()

	r := gin.Default()

	r.GET("/", func(c *gin.Context) {
		c.Header("Content-Type", "text/html; charset=utf-8")
		c.String(http.StatusOK, `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>go (gin)</title>
<style>body{font-family:system-ui;margin:3rem auto;max-width:40rem;line-height:1.6}</style></head>
<body><h1>go (gin)</h1><p>Gin app is running. Database engine: <code>%s</code>.</p>
<p>Edit <code>main.go</code> to build your solution. See <code>/db-status</code>.</p></body></html>`, engine)
	})

	r.GET("/health", func(c *gin.Context) { c.String(http.StatusOK, "ok") })

	r.GET("/db-status", func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusOK, gin.H{"database": engine, "connected": false})
			return
		}
		if err := db.Ping(); err != nil {
			c.JSON(http.StatusOK, gin.H{"database": engine, "connected": false, "error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"database": engine, "connected": true})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}
	log.Printf("go (gin) listening on :%s (database=%s)", port, engine)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
