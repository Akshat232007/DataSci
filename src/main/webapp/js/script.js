// DataSci JavaScript Helper Functions

document.addEventListener("DOMContentLoaded", function () {
    // Auto-dismiss alerts after 6 seconds if desired
    const alerts = document.querySelectorAll(".alert");
    alerts.forEach(function (alert) {
        setTimeout(function () {
            alert.style.transition = "opacity 0.5s ease";
            alert.style.opacity = "0.95";
        }, 5000);
    });
});

// Confirmation helper for destructive actions
function confirmAction(message) {
    return confirm(message || "Are you sure you want to proceed with this operation?");
}

// Data Cleaning dynamic form helper
function handleCleanOpChange() {
    const opSelect = document.getElementById("cleanOp");
    const colGroup = document.getElementById("colGroup");
    const renameGroup = document.getElementById("renameGroup");

    if (!opSelect) return;

    const val = opSelect.value;

    if (val === "removeMissing" || val === "removeDuplicates") {
        if (colGroup) colGroup.style.display = "none";
        if (renameGroup) renameGroup.style.display = "none";
    } else if (val === "renameColumn") {
        if (colGroup) colGroup.style.display = "block";
        if (renameGroup) renameGroup.style.display = "block";
    } else {
        if (colGroup) colGroup.style.display = "block";
        if (renameGroup) renameGroup.style.display = "none";
    }
}

// Live Linear Regression Prediction Helper
function calculatePrediction(slope, intercept) {
    const xInput = document.getElementById("predictX");
    const resultBox = document.getElementById("predictionResult");
    if (!xInput || !resultBox) return;

    const xVal = parseFloat(xInput.value);
    if (isNaN(xVal)) {
        resultBox.innerText = "Please enter a valid numeric value for X.";
        return;
    }

    const yHat = (slope * xVal) + intercept;
    resultBox.innerHTML = "<strong>Predicted Y (ŷ):</strong> " + yHat.toFixed(4);
}
