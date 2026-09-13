# google_mlkit_text_recognition tham chiếu TẤT CẢ bộ nhận diện chữ (Nhật/Hàn/Trung…)
# trong nhánh `initialize`, nhưng app chỉ đóng gói + dùng bộ Latin (offline, PBI 24)
# ⇒ R8 báo "Missing class" và chặn build release. Bỏ qua cảnh báo cho đúng gói này.
-dontwarn com.google.mlkit.vision.text.**
