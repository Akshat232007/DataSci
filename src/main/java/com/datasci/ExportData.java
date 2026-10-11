package com.datasci;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

@WebServlet("/ExportData")
public class ExportData extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp?error=Please login first");
            return;
        }

        @SuppressWarnings("unchecked")
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        @SuppressWarnings("unchecked")
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("home.jsp?error=No dataset to export");
            return;
        }

        String originalName = (String) session.getAttribute("current_file_name");
        String exportFileName = "datasci_exported.csv";
        if (originalName != null && originalName.endsWith(".csv")) {
            exportFileName = "processed_" + originalName;
        }

        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + exportFileName + "\"");

        PrintWriter out = response.getWriter();

        // Write header line
        out.println(formatLine(headers));

        // Write data lines
        for (List<String> row : rows) {
            out.println(formatLine(row));
        }
        out.flush();

        int userId = (int) session.getAttribute("user_id");
        Database.logHistory(userId, "Exported dataset", "Exported file: " + exportFileName + " (" + rows.size() + " rows)");
    }

    private String formatLine(List<String> items) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < items.size(); i++) {
            String item = items.get(i);
            if (item == null) {
                item = "";
            }
            if (item.contains(",") || item.contains("\"") || item.contains("\n")) {
                sb.append("\"").append(item.replace("\"", "\"\"")).append("\"");
            } else {
                sb.append(item);
            }
            if (i < items.size() - 1) {
                sb.append(",");
            }
        }
        return sb.toString();
    }
}
