<%@page import="java.util.List"%>
<%@page import="com.datasci.ReadData"%>
<%@page import="com.datasci.Database"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }

    String userName = (String) session.getAttribute("user_name");
    String userRole = (String) session.getAttribute("user_role");
    int userId = (int) session.getAttribute("user_id");
    String currentFileName = (String) session.getAttribute("current_file_name");

    @SuppressWarnings("unchecked")
    List<String> headers = (List<String>) session.getAttribute("dataset_headers");
    @SuppressWarnings("unchecked")
    List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

    boolean hasData = (headers != null && rows != null && !headers.isEmpty());
    List<String> numCols = hasData ? ReadData.getNumericalColumns(headers, rows) : null;
    List<String> catCols = hasData ? ReadData.getCategoricalColumns(headers, rows) : null;

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Visualize Charts — DataSci</title>
    <link rel="stylesheet" href="css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>

    <div class="navbar">
        <div class="nav-brand">
            <a href="home.jsp" style="text-decoration:none; color:inherit;">DataSci Platform</a>
        </div>
        <div class="nav-menu">
            <span class="nav-user">User: <%= userName %></span>
            <span class="badge-role <%= "ADMIN".equalsIgnoreCase(userRole) ? "role-admin" : "role-user" %>"><%= userRole %></span>
            <a href="Logout" class="btn btn-secondary btn-sm">Logout</a>
        </div>
    </div>

    <div class="app-container">
        <!-- Sidebar -->
        <div class="sidebar">
            <a href="Data?action=newUpload" class="btn-new-chat">+ Upload New CSV File</a>

            <div class="sidebar-title">Pipeline</div>
            <a href="home.jsp" class="sidebar-link">Dashboard</a>
            <a href="upload.jsp" class="sidebar-link">Upload Dataset</a>
            <a href="clean.jsp" class="sidebar-link">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="filter.jsp" class="sidebar-link">Filter and Sort</a>
            <a href="group.jsp" class="sidebar-link">Group By</a>
            <a href="charts.jsp" class="sidebar-link active">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>
            <a href="onehot.jsp" class="sidebar-link">One-Hot Encoding</a>

            <div class="sidebar-title">Dataset History</div>
            <% if (fileHistory.isEmpty()) { %>
                <div style="font-size: 11px; color: #888; padding: 4px 8px;">No saved files</div>
            <% } else { 
                for (Database.UploadedFile uf : fileHistory) { 
                    boolean isCurr = uf.fileName.equals(currentFileName);
            %>
                <a href="Data?action=openFile&id=<%= uf.id %>" class="sidebar-history-item <%= isCurr ? "current" : "" %>" title="Click to open <%= uf.fileName %>">
                    <%= isCurr ? "&bull; " : "" %><%= uf.fileName %>
                </a>
            <% } } %>

            <div class="sidebar-title">Workspace</div>
            <a href="ExportData" class="sidebar-link">Export CSV</a>
            <a href="history.jsp" class="sidebar-link">History</a>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Data Visualization</h2>
                <p style="font-size: 12px; color: #666;">Generate bar, line, pie, histogram, and scatter plots using Chart.js</p>
            </div>

            <!-- Warning Box (No emojis) -->
            <div class="warning-box">
                <strong>User Responsibility:</strong>
                DataSci generates the graph based on the columns selected by the user. It does not determine whether the relationship shown is meaningful. Please choose appropriate columns for your analysis.
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to plot charts.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else { %>
                <!-- Configuration Box -->
                <div class="box">
                    <div style="display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(0, 1.4fr) minmax(0, 1.4fr) auto; gap: 12px; align-items: flex-end;">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="chartType">Chart Type</label>
                            <select id="chartType" class="form-control" onchange="adjustControls();">
                                <option value="bar">Bar Chart</option>
                                <option value="line">Line Chart</option>
                                <option value="pie">Pie Chart</option>
                                <option value="histogram">Histogram</option>
                                <option value="scatter">Scatter Plot</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;" id="groupColX">
                            <label class="form-label" for="colX" id="labelColX">X Axis / Category Column</label>
                            <select id="colX" class="form-control">
                                <% for (String c : headers) { %>
                                    <option value="<%= c %>"><%= c %> (<%= numCols.contains(c) ? "Num" : "Cat" %>)</option>
                                <% } %>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;" id="groupColY">
                            <label class="form-label" for="colY" id="labelColY">Y Axis / Value Column</label>
                            <select id="colY" class="form-control">
                                <option id="optCountFreq" value="__COUNT__">-- Count Occurrences (Frequency) --</option>
                                <% for (String c : numCols) { %>
                                    <option value="<%= c %>"><%= c %> (Num)</option>
                                <% } %>
                            </select>
                        </div>

                        <div>
                            <button type="button" class="btn btn-primary" style="white-space: nowrap;" onclick="renderChart();">Render Chart</button>
                        </div>
                    </div>
                </div>

                <!-- Canvas Box -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title" id="chartHeaderTitle">Chart View</div>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="downloadChart();">Download PNG</button>
                    </div>

                    <div style="position: relative; height: 450px; width: 100%;">
                        <canvas id="mainChartCanvas"></canvas>
                    </div>
                </div>

                <script>
                    // ========================================================
                    // STEP 1: LOAD COMPLETE DATASET FROM SERVER (JSP)
                    // ========================================================
                    // Column header names
                    const tableHeaders = [
                        <% for (int i = 0; i < headers.size(); i++) { %>
                            "<%= headers.get(i).replace("\"", "\\\"") %>"<%= (i < headers.size() - 1 ? "," : "") %>
                        <% } %>
                    ];

                    // Data rows (All rows loaded without truncation)
                    const tableRows = [
                        <% for (int r = 0; r < rows.size(); r++) { 
                            List<String> row = rows.get(r);
                        %>
                            [
                                <% for (int c = 0; c < headers.size(); c++) { 
                                    String v = (c < row.size()) ? row.get(c).replace("\"", "\\\"") : "";
                                %>
                                    "<%= v %>"<%= (c < headers.size() - 1 ? "," : "") %>
                                <% } %>
                            ]<%= (r < rows.size() - 1 ? "," : "") %>
                        <% } %>
                    ];

                    // Variable to store the active Chart.js instance
                    let activeChart = null;

                    // Helper function: Find the column index by name
                    function getColumnIndex(columnName) {
                        for (let i = 0; i < tableHeaders.length; i++) {
                            if (tableHeaders[i] === columnName) {
                                return i;
                            }
                        }
                        return -1;
                    }

                    // Helper function: Destroy existing chart before creating a new one
                    function destroyPreviousChart() {
                        if (activeChart !== null) {
                            activeChart.destroy();
                            activeChart = null;
                        }
                    }

                    // ========================================================
                    // STEP 2: SHOW / HIDE CONTROLS BASED ON SELECTED CHART
                    // ========================================================
                    function adjustControls() {
                        const chartType = document.getElementById("chartType").value;
                        const groupColY = document.getElementById("groupColY");
                        const labelColX = document.getElementById("labelColX");
                        const labelColY = document.getElementById("labelColY");
                        const countOption = document.getElementById("optCountFreq");
                        const selectColY = document.getElementById("colY");

                        if (chartType === "histogram") {
                            // Histograms only need 1 numerical column (to calculate bins)
                            groupColY.style.display = "none";
                            labelColX.innerText = "Numerical Column for Bins";
                        } else if (chartType === "scatter") {
                            groupColY.style.display = "block";
                            labelColX.innerText = "X Axis (Numerical Column)";
                            labelColY.innerText = "Y Axis (Numerical Column)";
                            if (countOption) { countOption.style.display = "none"; }
                            if (selectColY.value === "__COUNT__" && selectColY.options.length > 1) {
                                selectColY.selectedIndex = 1;
                            }
                        } else if (chartType === "pie") {
                            // Pie chart supports both Frequency Count and Mean of values per category
                            groupColY.style.display = "block";
                            labelColX.innerText = "Category Column (Labels)";
                            labelColY.innerText = "Value Column (Optional)";
                            if (countOption) { countOption.style.display = "block"; }
                        } else {
                            groupColY.style.display = "block";
                            labelColX.innerText = "X Axis / Category Column";
                            labelColY.innerText = "Y Axis / Value Column";
                            if (countOption) { countOption.style.display = "none"; }
                            if (selectColY.value === "__COUNT__" && selectColY.options.length > 1) {
                                selectColY.selectedIndex = 1;
                            }
                        }
                    }

                    // ========================================================
                    // STEP 3: DEDICATED CHART DRAWING FUNCTIONS
                    // ========================================================

                    // --- 3.1: BAR CHART ---
                    function drawBarChart(ctx, colX, colY, idxX, idxY) {
                        let xLabels = [];
                        let yValues = [];

                        // Uses all records from dataset
                        for (let i = 0; i < tableRows.length; i++) {
                            let label = tableRows[i][idxX];
                            let value = parseFloat(tableRows[i][idxY]);
                            if (isNaN(value)) {
                                value = 0;
                            }
                            xLabels.push(label);
                            yValues.push(value);
                        }

                        activeChart = new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: xLabels,
                                datasets: [{
                                    label: colY,
                                    data: yValues,
                                    backgroundColor: '#2563eb'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: { beginAtZero: true }
                                }
                            }
                        });
                    }

                    // --- 3.2: LINE CHART ---
                    function drawLineChart(ctx, colX, colY, idxX, idxY) {
                        let xLabels = [];
                        let yValues = [];

                        // Uses all records from dataset
                        for (let i = 0; i < tableRows.length; i++) {
                            let label = tableRows[i][idxX];
                            let value = parseFloat(tableRows[i][idxY]);
                            if (isNaN(value)) {
                                value = 0;
                            }
                            xLabels.push(label);
                            yValues.push(value);
                        }

                        activeChart = new Chart(ctx, {
                            type: 'line',
                            data: {
                                labels: xLabels,
                                datasets: [{
                                    label: colY,
                                    data: yValues,
                                    borderColor: '#2563eb',
                                    backgroundColor: 'rgba(37, 99, 235, 0.1)',
                                    borderWidth: 2,
                                    fill: true
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: { beginAtZero: true }
                                }
                            }
                        });
                    }

                    // --- 3.3: PIE CHART ---
                    // Supports both:
                    // Mode A: Frequency / Count (when Value Column is Count Occurrences)
                    // Mode B: Mean / Average (when a numerical Value Column is selected)
                    function drawPieChart(ctx, colX, colY, idxX, idxY) {
                        let categoryCounts = {};
                        let categorySums = {};
                        let isCountMode = (colY === "__COUNT__" || idxY === -1);

                        // Process all records in the dataset
                        for (let i = 0; i < tableRows.length; i++) {
                            let category = tableRows[i][idxX];
                            if (!category || category.trim() === "") {
                                category = "(Unknown)";
                            } else {
                                category = category.trim();
                            }

                            if (categoryCounts[category] === undefined) {
                                categoryCounts[category] = 0;
                                categorySums[category] = 0;
                            }

                            // Every time the category appears, add 1 to its count
                            categoryCounts[category] += 1;

                            // If a numerical column is chosen, accumulate sum for calculating mean
                            if (!isCountMode) {
                                let num = parseFloat(tableRows[i][idxY]);
                                if (!isNaN(num)) {
                                    categorySums[category] += num;
                                }
                            }
                        }

                        let labels = Object.keys(categoryCounts);
                        let values = [];

                        for (let i = 0; i < labels.length; i++) {
                            let cat = labels[i];
                            if (isCountMode) {
                                // Mode A: Total occurrences
                                values.push(categoryCounts[cat]);
                            } else {
                                // Mode B: Mean (Average) = Sum / Count
                                let count = categoryCounts[cat];
                                let mean = (count > 0) ? (categorySums[cat] / count) : 0;
                                values.push(parseFloat(mean.toFixed(2)));
                            }
                        }

                        const palette = ['#2563eb', '#059669', '#d97706', '#dc2626', '#7c3aed', '#0891b2', '#4b5563', '#db2777', '#f59e0b', '#10b981', '#6366f1', '#ec4899'];
                        let colors = [];
                        for (let i = 0; i < labels.length; i++) {
                            colors.push(palette[i % palette.length]);
                        }

                        let datasetLabel = isCountMode ? ('Count of ' + colX) : ('Average ' + colY + ' by ' + colX);

                        activeChart = new Chart(ctx, {
                            type: 'pie',
                            data: {
                                labels: labels,
                                datasets: [{
                                    label: datasetLabel,
                                    data: values,
                                    backgroundColor: colors
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false
                            }
                        });
                    }

                    // --- 3.4: HISTOGRAM ---
                    function drawHistogram(ctx, colX, idxX) {
                        // Collect all valid numbers
                        let numbers = [];
                        for (let i = 0; i < tableRows.length; i++) {
                            let val = parseFloat(tableRows[i][idxX]);
                            if (!isNaN(val)) {
                                numbers.push(val);
                            }
                        }

                        if (numbers.length === 0) {
                            alert("No numerical data found in column: " + colX);
                            return;
                        }

                        // Find minimum and maximum
                        let min = Math.min(...numbers);
                        let max = Math.max(...numbers);
                        if (min === max) {
                            max = min + 1; // Avoid zero-width bins
                        }

                        // Create 7 equal-width bins
                        let binCount = 7;
                        let binWidth = (max - min) / binCount;

                        let binLabels = [];
                        let binFrequencies = [];
                        for (let b = 0; b < binCount; b++) {
                            let start = min + (b * binWidth);
                            let end = start + binWidth;
                            binLabels.push(start.toFixed(1) + " - " + end.toFixed(1));
                            binFrequencies.push(0);
                        }

                        // Count how many values fall into each bin
                        for (let i = 0; i < numbers.length; i++) {
                            let num = numbers[i];
                            let index = Math.floor((num - min) / binWidth);
                            if (index >= binCount) {
                                index = binCount - 1;
                            }
                            binFrequencies[index]++;
                        }

                        // Draw histogram as a bar chart of bin frequencies
                        activeChart = new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: binLabels,
                                datasets: [{
                                    label: 'Frequency Count in ' + colX,
                                    data: binFrequencies,
                                    backgroundColor: '#2563eb'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    x: { title: { display: true, text: colX + ' Range Bins' } },
                                    y: { title: { display: true, text: 'Frequency (Count)' }, beginAtZero: true }
                                }
                            }
                        });
                    }

                    // --- 3.5: SCATTER PLOT ---
                    function drawScatterPlot(ctx, colX, colY, idxX, idxY) {
                        let pointList = [];

                        // Collect all (x, y) coordinates from dataset
                        for (let i = 0; i < tableRows.length; i++) {
                            let xVal = parseFloat(tableRows[i][idxX]);
                            let yVal = parseFloat(tableRows[i][idxY]);

                            if (!isNaN(xVal) && !isNaN(yVal)) {
                                pointList.push({ x: xVal, y: yVal });
                            }
                        }

                        activeChart = new Chart(ctx, {
                            type: 'scatter',
                            data: {
                                datasets: [{
                                    label: colX + ' vs ' + colY,
                                    data: pointList,
                                    backgroundColor: '#2563eb'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    x: { title: { display: true, text: colX } },
                                    y: { title: { display: true, text: colY } }
                                }
                            }
                        });
                    }

                    // ========================================================
                    // STEP 4: MAIN CONTROLLER FUNCTION
                    // ========================================================
                    function renderChart() {
                        // 1. Read user selections
                        const chartType = document.getElementById("chartType").value;
                        const colX = document.getElementById("colX").value;
                        const colY = document.getElementById("colY").value;

                        // 2. Find column positions
                        const idxX = getColumnIndex(colX);
                        const idxY = getColumnIndex(colY);
                        if (idxX === -1) {
                            return;
                        }
                        if (chartType !== "pie" && chartType !== "histogram" && idxY === -1) {
                            return;
                        }

                        // 3. Clear previous chart
                        destroyPreviousChart();

                        // 4. Update box header title
                        let title = chartType.toUpperCase() + ": " + colX;
                        if (chartType === "pie") {
                            if (colY === "__COUNT__" || idxY === -1) {
                                title = "PIE CHART: Frequency Count of " + colX;
                            } else {
                                title = "PIE CHART: Average " + colY + " grouped by " + colX;
                            }
                        } else if (chartType !== "histogram") {
                            title += " vs " + colY;
                        }
                        document.getElementById("chartHeaderTitle").innerText = title;

                        // 5. Get canvas drawing context
                        const canvas = document.getElementById("mainChartCanvas");
                        const ctx = canvas.getContext("2d");

                        // 6. Draw selected chart type
                        if (chartType === "bar") {
                            drawBarChart(ctx, colX, colY, idxX, idxY);
                        } else if (chartType === "line") {
                            drawLineChart(ctx, colX, colY, idxX, idxY);
                        } else if (chartType === "pie") {
                            drawPieChart(ctx, colX, colY, idxX, idxY);
                        } else if (chartType === "histogram") {
                            drawHistogram(ctx, colX, idxX);
                        } else if (chartType === "scatter") {
                            drawScatterPlot(ctx, colX, colY, idxX, idxY);
                        }
                    }

                    // ========================================================
                    // STEP 5: DOWNLOAD CHART AS PNG IMAGE
                    // ========================================================
                    function downloadChart() {
                        const canvas = document.getElementById("mainChartCanvas");
                        const link = document.createElement("a");
                        link.download = "chart.png";
                        link.href = canvas.toDataURL("image/png");
                        link.click();
                    }

                    // When page loads, setup controls and render initial chart
                    document.addEventListener("DOMContentLoaded", function () {
                        adjustControls();
                        renderChart();
                    });
                </script>
            <% } %>
        </div>
    </div>

</body>
</html>
