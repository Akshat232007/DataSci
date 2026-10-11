package com.datasci;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@WebServlet("/Data")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2, // 2MB
    maxFileSize = 1024 * 1024 * 20,      // 20MB
    maxRequestSize = 1024 * 1024 * 30    // 30MB
)
public class Data extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        processRequest(request, response);
    }

    private void processRequest(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp?error=Please login first");
            return;
        }

        int userId = (int) session.getAttribute("user_id");
        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        try {
            if ("upload".equalsIgnoreCase(action)) {
                handleUpload(request, response, session, userId);
            } else if ("clean".equalsIgnoreCase(action)) {
                handleClean(request, response, session, userId);
            } else if ("filter".equalsIgnoreCase(action)) {
                handleFilter(request, response, session, userId);
            } else if ("sort".equalsIgnoreCase(action)) {
                handleSort(request, response, session, userId);
            } else if ("topBottom".equalsIgnoreCase(action)) {
                handleTopBottom(request, response, session, userId);
            } else if ("saveFiltered".equalsIgnoreCase(action)) {
                handleSaveFiltered(request, response, session, userId);
            } else if ("group".equalsIgnoreCase(action)) {
                handleGroup(request, response, session, userId);
            } else if ("stats".equalsIgnoreCase(action)) {
                handleStats(request, response, session, userId);
            } else if ("correlation".equalsIgnoreCase(action)) {
                handleCorrelation(request, response, session, userId);
            } else if ("regression".equalsIgnoreCase(action)) {
                handleRegression(request, response, session, userId);
            } else if ("encode".equalsIgnoreCase(action)) {
                handleEncode(request, response, session, userId);
            } else if ("saveEncoded".equalsIgnoreCase(action)) {
                handleSaveEncoded(request, response, session, userId);
            } else if ("openFile".equalsIgnoreCase(action) || "openDataset".equalsIgnoreCase(action)) {
                handleOpenFile(request, response, session, userId);
            } else if ("newUpload".equalsIgnoreCase(action)) {
                handleNewUpload(request, response, session, userId);
            } else if ("deleteFile".equalsIgnoreCase(action)) {
                handleDeleteFile(request, response, session, userId);
            } else {
                response.sendRedirect("home.jsp");
            }
        } catch (Exception e) {
            response.sendRedirect("home.jsp?error=Operation error: " + e.getMessage());
        }
    }

    private void handleUpload(HttpServletRequest request, HttpServletResponse response, 
                              HttpSession session, int userId) throws IOException, ServletException {
        Part filePart = request.getPart("csvFile");
        if (filePart == null || filePart.getSize() == 0) {
            response.sendRedirect("upload.jsp?error=Please select a CSV file to upload");
            return;
        }

        String submittedFileName = filePart.getSubmittedFileName();
        if (submittedFileName == null || !submittedFileName.toLowerCase().endsWith(".csv")) {
            response.sendRedirect("upload.jsp?error=Invalid file format. Only CSV files are accepted.");
            return;
        }

        // Prepare persistent uploads directory in user home
        File persistentDir = new File(System.getProperty("user.home"), "datasci_uploads");
        if (!persistentDir.exists()) {
            persistentDir.mkdirs();
        }

        String safeFileName = "user_" + userId + "_" + System.currentTimeMillis() + "_" + submittedFileName.replaceAll("[^a-zA-Z0-9.-]", "_");
        File targetFile = new File(persistentDir, safeFileName);

        try (InputStream input = filePart.getInputStream()) {
            Files.copy(input, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }

        // Also duplicate to webapp context uploads directory if available
        String webappUploadsPath = getServletContext().getRealPath("/uploads");
        if (webappUploadsPath != null) {
            File webappUploadsDir = new File(webappUploadsPath);
            if (!webappUploadsDir.exists()) {
                webappUploadsDir.mkdirs();
            }
            try {
                Files.copy(targetFile.toPath(), new File(webappUploadsDir, safeFileName).toPath(), StandardCopyOption.REPLACE_EXISTING);
            } catch (Exception e) {}
        }

        // Read and validate CSV contents
        List<List<String>> allRows = ReadData.readAll(targetFile.getAbsolutePath());
        if (allRows.isEmpty()) {
            targetFile.delete();
            response.sendRedirect("upload.jsp?error=The uploaded CSV file is empty.");
            return;
        }

        List<String> headers = ReadData.getHeaders(allRows);
        List<List<String>> dataRows = ReadData.getDataRows(allRows);

        if (headers.isEmpty()) {
            targetFile.delete();
            response.sendRedirect("upload.jsp?error=CSV must contain a header row with column names.");
            return;
        }

        session.setAttribute("current_file_name", submittedFileName);
        session.setAttribute("current_file_path", targetFile.getAbsolutePath());
        session.setAttribute("dataset_headers", headers);
        session.setAttribute("dataset_rows", dataRows);
        session.removeAttribute("filtered_rows");
        session.removeAttribute("group_result");
        session.removeAttribute("correlation_result");
        session.removeAttribute("regression_result");

        Database.logActivity(userId, submittedFileName, targetFile.getAbsolutePath(), dataRows.size(), headers.size(), "Uploaded Dataset");
        Database.logHistory(userId, "Uploaded dataset", "Uploaded " + submittedFileName + " (" + dataRows.size() + " rows, " + headers.size() + " columns)");

        response.sendRedirect("upload.jsp?msg=Dataset uploaded successfully!");
    }

    @SuppressWarnings("unchecked")
    private void handleClean(HttpServletRequest request, HttpServletResponse response, 
                             HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");
        String filePath = (String) session.getAttribute("current_file_path");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String cleanOp = request.getParameter("cleanOp");
        String column = request.getParameter("column");
        String message = "";

        if ("removeMissing".equalsIgnoreCase(cleanOp)) {
            int before = rows.size();
            List<List<String>> cleaned = CleanData.removeMissingRows(headers, rows);
            int removed = before - cleaned.size();
            session.setAttribute("dataset_rows", cleaned);
            message = "Removed " + removed + " rows containing missing values. " + cleaned.size() + " rows remain.";
            Database.logHistory(userId, "Removed missing values", message);
        } else if ("fillMean".equalsIgnoreCase(cleanOp)) {
            if (column == null || column.isEmpty()) {
                response.sendRedirect("clean.jsp?error=Please select a column to fill with mean.");
                return;
            }
            int filled = CleanData.fillMissingWithMean(headers, rows, column);
            if (filled == -1) {
                response.sendRedirect("clean.jsp?error=" + java.net.URLEncoder.encode("Column '" + column + "' contains no valid numerical values to calculate mean.", "UTF-8"));
                return;
            }
            message = "Filled " + filled + " missing value(s) in '" + column + "' using the column mean.";
            Database.logHistory(userId, "Filled missing values with mean", message);
        } else if ("fillMedian".equalsIgnoreCase(cleanOp)) {
            if (column == null || column.isEmpty()) {
                response.sendRedirect("clean.jsp?error=Please select a column to fill with median.");
                return;
            }
            int filled = CleanData.fillMissingWithMedian(headers, rows, column);
            if (filled == -1) {
                response.sendRedirect("clean.jsp?error=" + java.net.URLEncoder.encode("Column '" + column + "' contains no valid numerical values to calculate median.", "UTF-8"));
                return;
            }
            message = "Filled " + filled + " missing value(s) in '" + column + "' using the column median.";
            Database.logHistory(userId, "Filled missing values with median", message);
        } else if ("fillMode".equalsIgnoreCase(cleanOp)) {
            if (column == null || column.isEmpty()) {
                response.sendRedirect("clean.jsp?error=Please select a column to fill with mode.");
                return;
            }
            int filled = CleanData.fillMissingWithMode(headers, rows, column);
            if (filled == -1) {
                response.sendRedirect("clean.jsp?error=" + java.net.URLEncoder.encode("Column '" + column + "' contains no valid categorical values to calculate mode.", "UTF-8"));
                return;
            }
            message = "Filled " + filled + " missing value(s) in '" + column + "' using the column mode (first seen on ties).";
            Database.logHistory(userId, "Filled missing values with mode", message);
        } else if ("removeDuplicates".equalsIgnoreCase(cleanOp)) {
            int before = rows.size();
            List<List<String>> cleaned = CleanData.removeDuplicates(rows);
            int removed = before - cleaned.size();
            session.setAttribute("dataset_rows", cleaned);
            message = "Removed " + removed + " duplicate row(s). " + cleaned.size() + " rows remain.";
            Database.logHistory(userId, "Removed duplicates", message);
        } else if ("renameColumn".equalsIgnoreCase(cleanOp)) {
            String newName = request.getParameter("newColumnName");
            if (column == null || newName == null || newName.trim().isEmpty()) {
                response.sendRedirect("clean.jsp?error=Please specify both current column and new column name.");
                return;
            }
            boolean ok = CleanData.renameColumn(headers, column, newName.trim());
            if (ok) {
                message = "Renamed column '" + column + "' to '" + newName.trim() + "'.";
                Database.logHistory(userId, "Renamed column", message);
            } else {
                response.sendRedirect("clean.jsp?error=" + java.net.URLEncoder.encode("Could not rename column. Ensure new name is non-empty and does not duplicate an existing column.", "UTF-8"));
                return;
            }
        } else if ("deleteColumn".equalsIgnoreCase(cleanOp)) {
            if (column == null || column.isEmpty()) {
                response.sendRedirect("clean.jsp?error=Please select a column to delete.");
                return;
            }
            boolean ok = CleanData.deleteColumn(headers, rows, column);
            if (ok) {
                message = "Deleted column '" + column + "'.";
                Database.logHistory(userId, "Deleted column", message);
            } else {
                response.sendRedirect("clean.jsp?error=Could not delete column.");
                return;
            }
        }

        // Prevent stale results from previous operations
        session.removeAttribute("filtered_rows");
        session.removeAttribute("filter_info");
        session.removeAttribute("correlation_result");
        session.removeAttribute("group_result");
        session.removeAttribute("encoded_rows");
        session.removeAttribute("encoded_headers");

        // Sync modified dataset back to working disk file
        if (filePath != null) {
            ReadData.writeCSV(filePath, headers, (List<List<String>>) session.getAttribute("dataset_rows"));
        }

        response.sendRedirect("clean.jsp?msg=" + java.net.URLEncoder.encode(message, "UTF-8"));
    }

    @SuppressWarnings("unchecked")
    private void handleFilter(HttpServletRequest request, HttpServletResponse response, 
                              HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String column = request.getParameter("column");
        String operator = request.getParameter("operator");
        String valueStr = request.getParameter("targetValue");

        if (column == null || operator == null || valueStr == null || valueStr.trim().isEmpty()) {
            response.sendRedirect("filter.jsp?error=Please specify column, operator, and numerical value.");
            return;
        }

        try {
            double targetVal = Double.parseDouble(valueStr.trim());
            List<List<String>> filtered = FilterData.filter(headers, rows, column, operator, targetVal);
            session.setAttribute("filtered_rows", filtered);
            session.setAttribute("filter_info", "Filtered where " + column + " " + operator + " " + targetVal + " (matched " + filtered.size() + " of " + rows.size() + " rows)");

            Database.logHistory(userId, "Filtered data", "Condition: " + column + " " + operator + " " + targetVal + " (Results: " + filtered.size() + " rows)");
            response.sendRedirect("filter.jsp");
        } catch (NumberFormatException e) {
            response.sendRedirect("filter.jsp?error=Filter value must be a valid number.");
        }
    }

    @SuppressWarnings("unchecked")
    private void handleSort(HttpServletRequest request, HttpServletResponse response, 
                            HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String column = request.getParameter("sortColumn");
        String order = request.getParameter("sortOrder");
        boolean ascending = !"desc".equalsIgnoreCase(order);

        List<List<String>> currentRows = (List<List<String>>) session.getAttribute("filtered_rows");
        if (currentRows == null) {
            currentRows = rows;
        }

        List<List<String>> sorted = FilterData.sort(headers, currentRows, column, ascending);
        session.setAttribute("filtered_rows", sorted);
        session.setAttribute("filter_info", "Sorted by " + column + " (" + (ascending ? "Ascending" : "Descending") + ")");

        Database.logHistory(userId, "Sorted data", "Sorted by " + column + " (" + (ascending ? "Ascending" : "Descending") + ")");
        response.sendRedirect("filter.jsp");
    }

    @SuppressWarnings("unchecked")
    private void handleTopBottom(HttpServletRequest request, HttpServletResponse response, 
                                 HttpSession session, int userId) throws IOException {
        List<List<String>> currentRows = (List<List<String>>) session.getAttribute("filtered_rows");
        if (currentRows == null) {
            currentRows = (List<List<String>>) session.getAttribute("dataset_rows");
        }

        if (currentRows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String type = request.getParameter("tbType");
        String nStr = request.getParameter("tbCount");

        try {
            int n = Integer.parseInt(nStr.trim());
            List<List<String>> sliced;
            if ("bottom".equalsIgnoreCase(type)) {
                sliced = FilterData.getBottomN(currentRows, n);
                session.setAttribute("filter_info", "Viewing Bottom " + n + " rows");
            } else {
                sliced = FilterData.getTopN(currentRows, n);
                session.setAttribute("filter_info", "Viewing Top " + n + " rows");
            }
            session.setAttribute("filtered_rows", sliced);
            Database.logHistory(userId, "Top/Bottom Rows", "Selected " + type + " " + n + " rows");
            response.sendRedirect("filter.jsp");
        } catch (Exception e) {
            response.sendRedirect("filter.jsp?error=Please enter a valid positive number for N.");
        }
    }

    @SuppressWarnings("unchecked")
    private void handleSaveFiltered(HttpServletRequest request, HttpServletResponse response, 
                                    HttpSession session, int userId) throws IOException {
        List<List<String>> filtered = (List<List<String>>) session.getAttribute("filtered_rows");
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        String filePath = (String) session.getAttribute("current_file_path");

        if (filtered != null && headers != null) {
            session.setAttribute("dataset_rows", new ArrayList<>(filtered));
            session.removeAttribute("filtered_rows");
            session.removeAttribute("filter_info");
            if (filePath != null) {
                ReadData.writeCSV(filePath, headers, filtered);
            }
            Database.logHistory(userId, "Saved filtered dataset", "Working dataset updated to " + filtered.size() + " rows");
            response.sendRedirect("home.jsp?msg=Filtered view saved as current working dataset.");
        } else {
            response.sendRedirect("filter.jsp?error=No filtered rows to save.");
        }
    }

    @SuppressWarnings("unchecked")
    private void handleGroup(HttpServletRequest request, HttpServletResponse response, 
                             HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String groupCol = request.getParameter("groupCol");
        String operation = request.getParameter("operation");
        String numCol = request.getParameter("numCol");

        if (groupCol == null || groupCol.isEmpty()) {
            response.sendRedirect("group.jsp?error=Please select a column to group by.");
            return;
        }

        GroupData.GroupResult result = GroupData.group(headers, rows, groupCol, operation, numCol);
        session.setAttribute("group_result", result);
        session.setAttribute("last_group_col", groupCol);
        session.setAttribute("last_group_op", operation);
        session.setAttribute("last_group_num", numCol);

        Database.logHistory(userId, "Grouped data", "Group by " + groupCol + " with " + operation + (numCol != null && !numCol.isEmpty() ? " on " + numCol : ""));
        response.sendRedirect("group.jsp");
    }

    @SuppressWarnings("unchecked")
    private void handleStats(HttpServletRequest request, HttpServletResponse response, 
                             HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String column = request.getParameter("column");
        if (column == null || column.isEmpty()) {
            response.sendRedirect("stats.jsp?error=Please select a column.");
            return;
        }

        Database.logHistory(userId, "Calculated statistics", "Calculated statistical metrics for column: " + column);
        response.sendRedirect("stats.jsp?column=" + java.net.URLEncoder.encode(column, "UTF-8"));
    }

    @SuppressWarnings("unchecked")
    private void handleCorrelation(HttpServletRequest request, HttpServletResponse response, 
                                   HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String colX = request.getParameter("colX");
        String colY = request.getParameter("colY");

        if (colX == null || colY == null || colX.trim().isEmpty() || colY.trim().isEmpty()) {
            response.sendRedirect("correlation.jsp?error=Please select both X and Y columns.");
            return;
        }

        colX = colX.trim();
        colY = colY.trim();

        if (colX.equals(colY)) {
            response.sendRedirect("correlation.jsp?error=Please select two distinct numerical columns.");
            return;
        }

        List<String> numCols = ReadData.getNumericalColumns(headers, rows);
        if (!numCols.contains(colX) || !numCols.contains(colY)) {
            response.sendRedirect("correlation.jsp?error=Both selected columns must be numerical.");
            return;
        }

        Correlation.CorrelationResult result = Correlation.calculate(headers, rows, colX, colY);
        session.setAttribute("correlation_result", result);

        String logMsg = result.isDefined 
            ? ("Pearson correlation between " + colX + " and " + colY + ": r = " + String.format("%.4f", result.correlation))
            : ("Pearson correlation between " + colX + " and " + colY + ": " + result.rangeDescription);
        Database.logHistory(userId, "Calculated correlation", logMsg);
        response.sendRedirect("correlation.jsp");
    }

    private void handleRegression(HttpServletRequest request, HttpServletResponse response, 
                                  HttpSession session, int userId) throws IOException {
        response.sendRedirect("home.jsp?error=" + java.net.URLEncoder.encode("The Linear Regression feature is currently postponed.", "UTF-8"));
    }

    @SuppressWarnings("unchecked")
    private void handleEncode(HttpServletRequest request, HttpServletResponse response, 
                              HttpSession session, int userId) throws IOException {
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (headers == null || rows == null) {
            response.sendRedirect("upload.jsp?error=Please upload a dataset first.");
            return;
        }

        String[] selectedCols = request.getParameterValues("columns");
        if (selectedCols == null || selectedCols.length == 0) {
            response.sendRedirect("onehot.jsp?error=Please select at least one categorical column to encode.");
            return;
        }

        List<String> targetList = Arrays.asList(selectedCols);
        OneHotEncoding.EncodingResult result = OneHotEncoding.encode(headers, rows, targetList);

        if (!result.success) {
            response.sendRedirect("onehot.jsp?error=" + java.net.URLEncoder.encode(result.message, "UTF-8"));
            return;
        }

        session.setAttribute("encoded_result", result);
        Database.logHistory(userId, "One-Hot Encoding", result.message);
        response.sendRedirect("onehot.jsp?msg=" + java.net.URLEncoder.encode(result.message, "UTF-8"));
    }

    @SuppressWarnings("unchecked")
    private void handleSaveEncoded(HttpServletRequest request, HttpServletResponse response, 
                                  HttpSession session, int userId) throws IOException {
        OneHotEncoding.EncodingResult result = (OneHotEncoding.EncodingResult) session.getAttribute("encoded_result");
        String filePath = (String) session.getAttribute("current_file_path");

        if (result != null && result.success) {
            session.setAttribute("dataset_headers", new ArrayList<>(result.encodedHeaders));
            session.setAttribute("dataset_rows", new ArrayList<>(result.encodedRows));
            session.removeAttribute("encoded_result");
            session.removeAttribute("filtered_rows");
            session.removeAttribute("filter_info");
            session.removeAttribute("group_result");
            session.removeAttribute("correlation_result");

            if (filePath != null) {
                ReadData.writeCSV(filePath, result.encodedHeaders, result.encodedRows);
            }

            Database.logHistory(userId, "Saved One-Hot Encoded Dataset", "Working dataset updated to " + result.encodedColumnCount + " columns");
            response.sendRedirect("home.jsp?msg=" + java.net.URLEncoder.encode("Encoded dataset saved as current working dataset.", "UTF-8"));
        } else {
            response.sendRedirect("onehot.jsp?error=No encoded dataset found to save.");
        }
    }

    private void handleOpenFile(HttpServletRequest request, HttpServletResponse response, 
                                HttpSession session, int userId) throws IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            response.sendRedirect("history.jsp?error=Invalid file ID");
            return;
        }
        try {
            int fileId = Integer.parseInt(idStr);
            Database.UploadedFile file = Database.getUploadedFileById(fileId, userId);
            if (file == null || file.filePath == null) {
                response.sendRedirect("history.jsp?error=File record not found in history");
                return;
            }

            File diskFile = new File(file.filePath);
            if (!diskFile.exists()) {
                // Check fallback directories by file name
                String baseName = new File(file.filePath).getName();
                File fallback1 = new File(new File(System.getProperty("user.home"), "datasci_uploads"), baseName);
                String webappUploads = getServletContext().getRealPath("/uploads");
                File fallback2 = (webappUploads != null) ? new File(webappUploads, baseName) : null;
                File fallback3 = new File("uploads", baseName);

                if (fallback1.exists()) {
                    diskFile = fallback1;
                } else if (fallback2 != null && fallback2.exists()) {
                    diskFile = fallback2;
                } else if (fallback3.exists()) {
                    diskFile = fallback3;
                }

                // If found in a fallback location, repair recorded path
                if (diskFile.exists()) {
                    Database.updateFilePath(fileId, userId, diskFile.getAbsolutePath());
                }
            }

            if (!diskFile.exists()) {
                response.sendRedirect("history.jsp?error=File no longer exists on server disk");
                return;
            }

            List<List<String>> allRows = ReadData.readAll(diskFile.getAbsolutePath());
            if (allRows.isEmpty()) {
                response.sendRedirect("history.jsp?error=The selected file is empty");
                return;
            }
            List<String> headers = ReadData.getHeaders(allRows);
            List<List<String>> dataRows = ReadData.getDataRows(allRows);

            session.setAttribute("current_file_name", file.fileName);
            session.setAttribute("current_file_path", diskFile.getAbsolutePath());
            session.setAttribute("dataset_headers", headers);
            session.setAttribute("dataset_rows", dataRows);
            session.removeAttribute("filtered_rows");
            session.removeAttribute("filter_info");
            session.removeAttribute("group_result");
            session.removeAttribute("correlation_result");
            session.removeAttribute("regression_result");

            Database.logHistory(userId, "Opened dataset from history", "Loaded " + file.fileName + " (" + dataRows.size() + " rows)");
            response.sendRedirect("home.jsp?msg=" + java.net.URLEncoder.encode("Opened " + file.fileName + " from history", "UTF-8"));
        } catch (Exception e) {
            response.sendRedirect("history.jsp?error=Error opening file: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private void handleNewUpload(HttpServletRequest request, HttpServletResponse response, 
                                 HttpSession session, int userId) throws IOException {
        String currentPath = (String) session.getAttribute("current_file_path");
        String currentName = (String) session.getAttribute("current_file_name");
        List<String> headers = (List<String>) session.getAttribute("dataset_headers");
        List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

        if (currentPath != null && headers != null && rows != null) {
            ReadData.writeCSV(currentPath, headers, rows);
            Database.logHistory(userId, "Saved dataset state", "Saved state of " + currentName + " before starting new upload");
        }

        session.removeAttribute("current_file_name");
        session.removeAttribute("current_file_path");
        session.removeAttribute("dataset_headers");
        session.removeAttribute("dataset_rows");
        session.removeAttribute("filtered_rows");
        session.removeAttribute("filter_info");
        session.removeAttribute("group_result");
        session.removeAttribute("correlation_result");
        session.removeAttribute("regression_result");

        response.sendRedirect("upload.jsp?msg=" + java.net.URLEncoder.encode("Previous dataset saved. You can now upload a new CSV file.", "UTF-8"));
    }

    private void handleDeleteFile(HttpServletRequest request, HttpServletResponse response, 
                                  HttpSession session, int userId) throws IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int fileId = Integer.parseInt(idStr);
                Database.deleteUploadedFile(fileId, userId);
                Database.logHistory(userId, "Deleted file record", "Removed file ID " + fileId + " from history");
            } catch (Exception e) {}
        }
        response.sendRedirect("history.jsp?msg=" + java.net.URLEncoder.encode("File entry removed from history.", "UTF-8"));
    }
}
