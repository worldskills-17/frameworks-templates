// vanilla-go: a dependency-free Go web app (stdlib net/http only).
// Builds fully offline - no module proxy or mirror needed.
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
)

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "ok")
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprintf(w, `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>vanilla-go</title>
<style>body{font-family:system-ui;margin:3rem auto;max-width:40rem;line-height:1.6}</style></head>
<body><h1>vanilla-go</h1>
<p>A dependency-free Go app (%s) using the standard library net/http.</p>
<p>Edit <code>main.go</code> to build your solution.</p></body></html>`, runtime.Version())
	})

	// The competition container listens on :80 (overridable via PORT).
	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}
	addr := ":" + port
	log.Printf("vanilla-go listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
