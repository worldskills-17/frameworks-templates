package uk.worldskills.module;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AppController {

    /** Resolve the DB engine name from DATABASE_URL ("none" when unset). */
    private String engine() {
        String url = System.getenv("DATABASE_URL");
        if (url == null || url.isBlank()) {
            return "none";
        }
        if (url.startsWith("postgres")) {
            return "postgres";
        }
        if (url.startsWith("mysql")) {
            return "mysql";
        }
        return "unsupported";
    }

    @GetMapping(value = "/", produces = MediaType.TEXT_HTML_VALUE)
    public String index() {
        return "<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><title>spring-boot</title>"
             + "<style>body{font-family:system-ui;margin:3rem auto;max-width:40rem;line-height:1.6}</style></head>"
             + "<body><h1>spring-boot</h1><p>Spring Boot app is running. Database engine: <code>"
             + engine() + "</code>.</p><p>Edit <code>AppController.java</code> to build your solution."
             + " See <code>/db-status</code>.</p></body></html>";
    }

    @GetMapping(value = "/health", produces = MediaType.TEXT_PLAIN_VALUE)
    public String health() {
        return "ok";
    }

    @GetMapping(value = "/db-status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> dbStatus() {
        Map<String, Object> out = new LinkedHashMap<>();
        String raw = System.getenv("DATABASE_URL");
        String eng = engine();
        out.put("database", eng);
        if (raw == null || raw.isBlank() || eng.equals("none") || eng.equals("unsupported")) {
            out.put("connected", false);
            return out;
        }
        try {
            URI u = new URI(raw);
            String user = "";
            String pass = "";
            if (u.getUserInfo() != null) {
                String[] ui = u.getUserInfo().split(":", 2);
                user = URLDecoder.decode(ui[0], StandardCharsets.UTF_8);
                if (ui.length > 1) {
                    pass = URLDecoder.decode(ui[1], StandardCharsets.UTF_8);
                }
            }
            String host = u.getHost();
            int port = u.getPort();
            String path = u.getPath();
            String db = (path != null && path.length() > 1) ? path.substring(1) : "";
            String jdbc;
            if (eng.equals("postgres")) {
                if (port < 0) {
                    port = 5432;
                }
                jdbc = "jdbc:postgresql://" + host + ":" + port + "/" + db + "?sslmode=disable";
            } else {
                if (port < 0) {
                    port = 3306;
                }
                jdbc = "jdbc:mysql://" + host + ":" + port + "/" + db;
            }
            try (Connection c = DriverManager.getConnection(jdbc, user, pass);
                 Statement s = c.createStatement()) {
                s.execute("SELECT 1");
                out.put("connected", true);
            }
        } catch (Exception e) {
            out.put("connected", false);
            out.put("error", e.getMessage());
        }
        return out;
    }
}
