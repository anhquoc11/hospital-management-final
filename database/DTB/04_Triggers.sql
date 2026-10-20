-- DML and database triggers
USE [QuanLyBenhVien];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   TRIGGER TRG_CapNhatTrangThaiGiuong
ON NoiTru
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nếu giường đã có người khác đang nằm
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN NoiTru nt ON i.MaGiuong = nt.MaGiuong
        WHERE i.TrangThai = 'DangNam' 
          AND nt.TrangThai = 'DangNam'
          AND i.MaNoiTru <> nt.MaNoiTru
    )
    BEGIN
        RAISERROR (N'Lỗi: Giường này hiện đang có bệnh nhân khác sử dụng!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Cập nhật giường sang 'DangSuDung' khi nhập viện
    UPDATE g
    SET g.TrangThai = 'DangSuDung'
    FROM GiuongBenh g
    JOIN inserted i ON g.MaGiuong = i.MaGiuong
    WHERE i.TrangThai = 'DangNam';

    -- Trả giường về 'Trong' khi xuất viện hoặc chuyển khoa
    UPDATE g
    SET g.TrangThai = 'Trong'
    FROM GiuongBenh g
    JOIN inserted i ON g.MaGiuong = i.MaGiuong
    WHERE i.TrangThai IN ('DaXuatVien', 'ChuyenKhoa');
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO
CREATE   TRIGGER trg_KetQuaCLS_Notification ON dbo.KetQuaCLS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Náº¿u cá»™t KetLuan Ä‘Æ°á»£c cáº­p nháº­t (nghÄ©a lÃ  Ä‘Ã£ cÃ³ káº¿t luáº­n)
    IF UPDATE(KetLuan)
    BEGIN
        INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
        SELECT 
            tk.MaTaiKhoan,
            N'Káº¿t quáº£ xÃ©t nghiá»‡m/CÄHA má»›i',
            N'Káº¿t quáº£ dá»‹ch vá»¥ "' + d.TenDichVu + N'" cá»§a báº¡n Ä‘Ã£ cÃ³. Vui lÃ²ng kiá»ƒm tra má»¥c Há»“ sÆ¡ bá»‡nh Ã¡n.',
            'KET_QUA_XN'
        FROM inserted i
        JOIN deleted d_old ON i.MaKetQua = d_old.MaKetQua
        JOIN dbo.PhieuKham pk ON i.MaPhieuKham = pk.MaPhieuKham
        JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan
        JOIN dbo.TaiKhoan tk ON bn.MaTaiKhoan = tk.MaTaiKhoan
        JOIN dbo.DichVuCLS d ON i.MaDichVu = d.MaDichVu
        WHERE i.KetLuan IS NOT NULL AND (d_old.KetLuan IS NULL OR d_old.KetLuan = '');
    END
END;
GO
