# zajil-express
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zajil Express Trading</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    
    <!-- مكتبات Firebase السحابية -->
    <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-storage-compat.js"></script>
</head>
<body>

    <!-- شاشة تسجيل الدخول -->
    <div id="loginSection" class="auth-card">
        <div class="brand">
            <h1>Zajil Express Trading</h1>
            <p>تسجيل الدخول للنظام السحابي</p>
        </div>
        <form id="loginForm">
            <div class="form-group">
                <label>البريد الإلكتروني / اسم المستخدم:</label>
                <input type="email" id="loginEmail" required placeholder="admin@zajil.com">
            </div>
            <div class="form-group">
                <label>كلمة المرور:</label>
                <input type="password" id="loginPassword" required placeholder="******">
            </div>
            <button type="submit" class="btn-primary">دخول النظام</button>
        </form>
    </div>

    <!-- النظام الرئيسي (يظهر فقط بعد تسجيل الدخول) -->
    <div id="mainApp" class="container" style="display: none;">
        <header>
            <div class="brand">
                <h1>Zajil Express Trading</h1>
                <p>نظام إدخال الحسابات اليومية والأرشيف السحابي</p>
            </div>
            <button id="logoutBtn" class="btn-logout">تسجيل الخروج 🚪</button>
        </header>

        <!-- نموذج الإدخال اليومي -->
        <section class="card">
            <h2>تسجيل حركة يومية جديدة</h2>
            <form id="entryForm">
                <div class="form-grid-3">
                    <div class="form-group">
                        <label>التاريخ:</label>
                        <input type="date" id="entryDate" required>
                    </div>
                    <div class="form-group">
                        <label>الموازنة التقديرية (SAR):</label>
                        <input type="number" step="0.01" id="budget" placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label>إجمالي المقبوضات / الإيرادات (SAR):</label>
                        <input type="number" step="0.01" id="income" placeholder="0.00" required>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label>إجمالي المصاريف / أجور الورشة (SAR):</label>
                        <input type="number" step="0.01" id="expenses" placeholder="0.00" required>
                    </div>
                    
                    <div class="form-group">
                        <label>📷 صور ورقة مدى / الأوراق (من الجوال أو الكاميرا):</label>
                        <input type="file" id="posImageInput" accept="image/*" multiple class="file-control">
                        <small class="help-text">اختر الصور المحفوظة بالجوال أو التقط صورة فورية.</small>
                    </div>
                </div>

                <div class="form-group">
                    <label>📄 ملفات PDF / الحوالات البنكية (المحفوظة بالجوال):</label>
                    <input type="file" id="pdfFileInput" accept="application/pdf" multiple class="file-control">
                    <small class="help-text">اختر ملفات الـ PDF المحفوظة في ذاكرة الجوال (Downloads/Files).</small>
                </div>

                <div class="form-group">
                    <label>ملاحظات اليوم والعمل:</label>
                    <textarea id="notes" rows="3" placeholder="اكتب أي ملاحظات خاصة بالحسابات أو الحوالات..."></textarea>
                </div>

                <button type="submit" id="saveBtn" class="btn-primary">حفظ في الحساب السحابي ☁️</button>
            </form>
        </section>

        <!-- مراجعة الأرشيف وتصدير التقارير -->
        <section class="card">
            <h2>مراجعة الأرشيف السحابي وتصدير التقارير</h2>
            <div class="search-box">
                <input type="date" id="searchDate">
                <button id="searchBtn" class="btn-primary">بحث باليوم</button>
                <button id="resetBtn" class="btn-outline">عرض الكل</button>
            </div>

            <div id="resultsContainer" class="results-list"></div>
        </section>
    </div>

    <!-- نافذة معاينة الصور -->
    <div id="imageModal" class="modal">
        <span class="close-modal" id="closeModal">&times;</span>
        <img class="modal-content" id="modalImg">
    </div>

    <script src="app.js"></script>
</body>
</html>
