<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Register — DataSci</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <div class="navbar">
        <div class="nav-brand">
            <a href="index.jsp" style="text-decoration:none; color:inherit;">DataSci Platform</a>
        </div>
        <div class="nav-menu">
            <a href="index.jsp">Home</a>
            <a href="login.jsp" class="btn btn-secondary btn-sm">Login</a>
        </div>
    </div>

    <div class="auth-page">
        <div class="auth-box">
            <div class="auth-header">
                <h1>Create Account</h1>
                <p>Register as a student or analyst</p>
            </div>

            <% 
                String error = request.getParameter("error");
                String msg = request.getParameter("msg");
                if (error != null) { 
            %>
                <div class="alert alert-danger"><%= error %></div>
            <% } %>

            <% if (msg != null) { %>
                <div class="alert alert-success"><%= msg %></div>
            <% } %>

            <form action="Register" method="POST">
                <div class="form-group">
                    <label class="form-label" for="name">Full Name</label>
                    <input type="text" id="name" name="name" class="form-control" placeholder="e.g. John Doe" required autofocus>
                </div>

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="name@example.com" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-control" placeholder="Enter password" required>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 8px;">Create Account</button>
            </form>

            <div style="margin-top: 15px; text-align: center; font-size: 13px; color: #666;">
                Already have an account? <a href="login.jsp">Sign in here</a>
            </div>
        </div>
    </div>

</body>
</html>
