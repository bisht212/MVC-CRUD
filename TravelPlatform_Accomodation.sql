---------------steps to add data to table----------------------
/*
1. add data to vendormaster (Personal & Business Information, Contact Details, Financial & Legal Details,Payment Terms, Documents)
2. Hotel Registration (General Details,Restaurants on Property,Banquet on Property,Contact Details,Hotel Facilities,Hotel Images)
3. Hotel Room Details
4. Add Hotel Price
*/
---------------------------------------------------------------
select * from VendorMaster
select * from servicemaster
select * from se
update servicemaster set service_name='Hotel' where service_id=14

CREATE TABLE dbo.VendorMaster
(
    TenantID        INT NOT NULL,
    VendorID        INT IDENTITY(1,1) NOT NULL,
	VendorCode      VARCHAR(50) NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    services VARCHAR(255), 
    star_rating TINYINT CHECK (star_rating BETWEEN 1 AND 5),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city INT NOT NULL,
    state INT NOT NULL,
    country INT NOT NULL,
    pin_code VARCHAR(20) NULL,
    business_type INT NOT NULL,
	IsActive        BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
	created_by      NVARCHAR(100) NULL,
    updated_at DATETIME NULL ,
    updated_by      NVARCHAR(100) NULL,
	approved_at DATETIME NULL,
    approved_by      NVARCHAR(100) NULL,
	IsPublish BIT NOT NULL DEFAULT 0,
	IsDraft BIT NOT NULL DEFAULT 1,
	approval_remarks NVARCHAR(1000) NULL,
    PRIMARY KEY (TenantID, VendorID),

    CONSTRAINT UQ_Vendor UNIQUE (TenantID, business_name)
);



CREATE TABLE dbo.servicemaster (
    service_id INT IDENTITY(1,1) NOT NULL,
    service_name VARCHAR(100) UNIQUE NOT NULL,
	IsActive BIT, SortOrder int
);

CREATE TABLE vendor_services (
    VendorID BIGINT,  --REFERENCES VendorMaster(VendorID)
    service_id BIGINT, --REFERENCES services(service_id)
    PRIMARY KEY (VendorID, service_id),
   
);



--INSERT INTO business_services (business_id, service_id)
--VALUES
--(1, 1), -- Hotel
--(1, 2), -- Restaurant
--(1, 3); -- Spa


CREATE TABLE business_type (
    business_type INT IDENTITY(1,1) NOT NULL,
    business_typename VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dbo.VendorContacts
(
    VendorContactId INT IDENTITY(1,1) NOT NULL,
    TenantID        INT NOT NULL,
    VendorID        INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    department VARCHAR(100),
    designation VARCHAR(100),
    created_at  DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (VendorContactId,TenantID, VendorID)
);


CREATE TABLE dbo.VendorLegalFinancial
(
	VendorLegalFinancialid INT identity(1,1) PRIMARY KEY,
    TenantID        INT NOT NULL,
    VendorID        INT NOT NULL,
   -- Bank Details
   legal_name            VARCHAR(50),
    bank_name            VARCHAR(50),
    account_number       VARCHAR(30),
    ifsc_code             VARCHAR(15),
    applicable_tds_percent DECIMAL(5,2),

    -- PAN Details
    pan_holder_name      VARCHAR(50),
    pan_number           VARCHAR(10),

    -- GST Details
    gst_registered_name  VARCHAR(150),
    gstin_number         VARCHAR(15),

    -- MSME Details
    msme_certificate_holder_name VARCHAR(150),
    msme_registration_number     VARCHAR(50),

    -- TAN Details
    tan_number           VARCHAR(10),

    -- Meta fields
    is_bank_verified     tinyint DEFAULT 0,
    is_pan_verified      tinyint DEFAULT 0,
    is_gst_verified      tinyint DEFAULT 0,

    created_at           DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at           DATETIME NULL,

	approved_at DATETIME NULL,
    approved_by      NVARCHAR(100) NULL   
);

CREATE TABLE dbo.VendorPaymentTerms
(
    VendorPaymentTermsId INT IDENTITY(1,1),
    TenantID        INT NOT NULL,
    VendorID        INT NOT NULL,
    Terms     VARCHAR(50),     -- Bill To Company, Pay In Advance
	CreditType  VARCHAR(50), 
	CreditDays int    
);

CREATE TABLE dbo.VendorDocuments
(
    TenantID        INT NOT NULL,
    DocumentID      INT IDENTITY(1,1),
    VendorID        INT NOT NULL,
    DocumentType    VARCHAR(50),     -- PAN, GST, Hotel Licence, MSME, Canceled Cheque,AadharNo
    DocumentName    NVARCHAR(200),
    FilePath        NVARCHAR(500),
    UploadedOn      DATETIME DEFAULT GETDATE(),
    IsVerified      BIT DEFAULT 0,
	approved_at DATETIME NULL,
    approved_by      NVARCHAR(100) NULL   
    PRIMARY KEY (TenantID, DocumentID)
);

ALTER PROCEDURE dbo.usp_VendorMaster_Save
(
    @TenantID INT,
    @VendorID INT = NULL,   -- NULL = INSERT, NOT NULL = UPDATE
    @business_name VARCHAR(255),
    @legal_name VARCHAR(255),
    @services VARCHAR(255),
    @star_rating TINYINT,
    @address_line1 VARCHAR(255),
    @address_line2 VARCHAR(255),
    @city INT,
    @state INT,
    @country INT,
    @pin_code VARCHAR(20),
    @business_type INT,
    @UserName NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewVendorID INT;

    -- Duplicate check (within tenant)
    IF EXISTS (
        SELECT 1 
        FROM dbo.VendorMaster
        WHERE TenantID = @TenantID
          AND business_name = @business_name
          AND (@VendorID IS NULL OR VendorID <> @VendorID)
    )
    BEGIN
        RAISERROR ('Vendor with same business name already exists.', 16, 1);
        RETURN;
    END

    -- INSERT
    IF @VendorID IS NULL
    BEGIN
        INSERT INTO dbo.VendorMaster
        (
            TenantID,
            business_name,
            legal_name,
            services,
            star_rating,
            address_line1,
            address_line2,
            city,
            state,
            country,
            pin_code,
            business_type,
            created_by
        )
        VALUES
        (
            @TenantID,
            @business_name,
            @legal_name,
            @services,
            @star_rating,
            @address_line1,
            @address_line2,
            @city,
            @state,
            @country,
            @pin_code,
            @business_type,
            @UserName
        );

        SET @NewVendorID = SCOPE_IDENTITY();

        -- Generate VendorCode like VN000001
        UPDATE dbo.VendorMaster
        SET VendorCode = 'VN' + RIGHT('000000' + CAST(@NewVendorID AS VARCHAR(6)), 6)
        WHERE VendorID = @NewVendorID;

        SELECT 
            @NewVendorID AS VendorID,
            'VN' + RIGHT('000000' + CAST(@NewVendorID AS VARCHAR(6)), 6) AS VendorCode;
    END
    ELSE
    BEGIN
        -- UPDATE (VendorCode NOT changed)
        UPDATE dbo.VendorMaster
        SET
            business_name = @business_name,
            legal_name = @legal_name,
            services = @services,
            star_rating = @star_rating,
            address_line1 = @address_line1,
            address_line2 = @address_line2,
            city = @city,
            state = @state,
            country = @country,
            pin_code = @pin_code,
            business_type = @business_type,
            updated_at = GETDATE(),
            updated_by = @UserName
        WHERE TenantID = @TenantID
          AND VendorID = @VendorID;

        SELECT 
            @VendorID AS VendorID,
            VendorCode
        FROM dbo.VendorMaster
        WHERE VendorID = @VendorID AND TenantID = @TenantID
    END
END;
GO


--Vendor Services Mapping (Replace Mapping)
CREATE PROCEDURE dbo.usp_VendorServices_Save
(
    @VendorID INT,
    @ServiceIDs VARCHAR(200) -- comma separated: 1,2,3
)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM vendor_services WHERE VendorID = @VendorID;

    INSERT INTO vendor_services (VendorID, service_id)
    SELECT @VendorID, value
    FROM STRING_SPLIT(@ServiceIDs, ',');
END;
GO

--Vendor Contacts – Add / Update
CREATE PROCEDURE dbo.usp_VendorContact_Save
(
    @VendorContactId INT = NULL,
    @TenantID INT,
    @VendorID INT,
    @full_name VARCHAR(100),
    @phone VARCHAR(20),
    @email VARCHAR(150),
    @department VARCHAR(100),
    @designation VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @VendorContactId IS NULL
    BEGIN
        INSERT INTO dbo.VendorContacts
        (
            TenantID, VendorID, full_name, phone, email, department, designation
        )
        VALUES
        (
            @TenantID, @VendorID, @full_name, @phone, @email, @department, @designation
        );
    END
    ELSE
    BEGIN
        UPDATE dbo.VendorContacts
        SET
            full_name = @full_name,
            phone = @phone,
            email = @email,
            department = @department,
            designation = @designation
        WHERE VendorContactId = @VendorContactId
          AND TenantID = @TenantID
          AND VendorID = @VendorID;
    END
END;
GO

--Vendor Legal & Financial – Add / Update (1 row per Vendor)
CREATE PROCEDURE dbo.usp_VendorLegalFinancial_Save
(
    @TenantID INT,
    @VendorID INT,
    @bank_name VARCHAR(50),
    @account_number VARCHAR(30),
    @ifsc_code VARCHAR(15),
    @applicable_tds_percent DECIMAL(5,2),
    @pan_holder_name VARCHAR(50),
    @pan_number VARCHAR(10),
    @gst_registered_name VARCHAR(150),
    @gstin_number VARCHAR(15),
    @msme_certificate_holder_name VARCHAR(150),
    @msme_registration_number VARCHAR(50),
    @tan_number VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.VendorLegalFinancial
        WHERE TenantID = @TenantID AND VendorID = @VendorID
    )
    BEGIN
        UPDATE dbo.VendorLegalFinancial
        SET
            bank_name = @bank_name,
            account_number = @account_number,
            ifsc_code = @ifsc_code,
            applicable_tds_percent = @applicable_tds_percent,
            pan_holder_name = @pan_holder_name,
            pan_number = @pan_number,
            gst_registered_name = @gst_registered_name,
            gstin_number = @gstin_number,
            msme_certificate_holder_name = @msme_certificate_holder_name,
            msme_registration_number = @msme_registration_number,
            tan_number = @tan_number,
            updated_at = GETDATE()
        WHERE TenantID = @TenantID
          AND VendorID = @VendorID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.VendorLegalFinancial
        (
            TenantID, VendorID, bank_name, account_number, ifsc_code,
            applicable_tds_percent, pan_holder_name, pan_number,
            gst_registered_name, gstin_number,
            msme_certificate_holder_name, msme_registration_number,
            tan_number
        )
        VALUES
        (
            @TenantID, @VendorID, @bank_name, @account_number, @ifsc_code,
            @applicable_tds_percent, @pan_holder_name, @pan_number,
            @gst_registered_name, @gstin_number,
            @msme_certificate_holder_name, @msme_registration_number,
            @tan_number
        );
    END
END;
GO

--Vendor Payment Terms – Add / Update
CREATE PROCEDURE dbo.usp_VendorPaymentTerms_Save
(
    @TenantID INT,
    @VendorID INT,
    @Terms VARCHAR(50),
    @CreditType VARCHAR(50),
    @CreditDays INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.VendorPaymentTerms
        WHERE TenantID = @TenantID AND VendorID = @VendorID
    )
    BEGIN
        UPDATE dbo.VendorPaymentTerms
        SET
            Terms = @Terms,
            CreditType = @CreditType,
            CreditDays = @CreditDays
        WHERE TenantID = @TenantID
          AND VendorID = @VendorID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.VendorPaymentTerms
        (TenantID, VendorID, Terms, CreditType, CreditDays)
        VALUES
        (@TenantID, @VendorID, @Terms, @CreditType, @CreditDays);
    END
END;
GO

--Vendor Documents – Add
CREATE PROCEDURE dbo.usp_VendorDocument_Add
(
    @TenantID INT,
    @VendorID INT,
    @DocumentType VARCHAR(50),
    @DocumentName NVARCHAR(200),
    @FilePath NVARCHAR(500)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.VendorDocuments
    (
        TenantID, VendorID, DocumentType, DocumentName, FilePath
    )
    VALUES
    (
        @TenantID, @VendorID, @DocumentType, @DocumentName, @FilePath
    );
END;
GO

CREATE PROCEDURE dbo.usp_GetVendorList_ByIsActive
(
    @TenantID INT,
    @IsActive BIT = NULL   -- NULL = All, 1 = Active, 0 = Inactive
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        vm.VendorID,
        vm.VendorCode,
        vm.business_name,
        vm.legal_name,
        vm.star_rating,
        vm.city,
        vm.state,
        vm.country,
        vm.IsActive,
        vm.IsPublish,
        vm.IsDraft,
        vm.created_at,
        vm.updated_at
    FROM dbo.VendorMaster vm
    WHERE vm.TenantID = @TenantID
      AND (
            @IsActive IS NULL 
            OR vm.IsActive = @IsActive
          )
    ORDER BY vm.business_name;
END;
GO

CREATE PROCEDURE dbo.usp_Vendor_SubmitForApproval
(
    @VendorID INT,
	@TenantID INT,
    @BranchCode VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @ApproverID VARCHAR(50),
        @EmailId VARCHAR(100);

    -- Fetch active approver as per branch
    SELECT TOP 1
        @ApproverID = ApproverID,
        @EmailId = EmailId
    FROM dbo.ApproverMaster
    WHERE BranchCode = @BranchCode
      AND IsActive = 1
    ORDER BY Id;  -- first approver (can change rule)

    -- Safety check
    IF @ApproverID IS NULL
    BEGIN
        RAISERROR ('No active approver found for this branch.', 16, 1);
        RETURN;
    END

    -- Update VendorMaster
    UPDATE dbo.VendorMaster
    SET
        IsDraft = 0,  -- final submission     
        updated_at = GETDATE()
    WHERE VendorID = @VendorID AND TenantID = @TenantID;

    -- Return updated data (useful for UI)
    SELECT
        VendorID,
        IsDraft,
        @ApproverID As ApproverID,
        @EmailId as ApproverEmail        
    FROM dbo.VendorMaster
    WHERE VendorID = @VendorID AND TenantID = @TenantID
END;
GO


CREATE TABLE dbo.MailLog
(
    MailLogID INT IDENTITY(1,1) PRIMARY KEY,

    ModuleName VARCHAR(50) NOT NULL,   -- VendorApproval / Payment / Booking
    ReferenceID INT NOT NULL,           -- VendorID

    ToEmail VARCHAR(500) NOT NULL,
    CcEmail VARCHAR(500) NULL,
    BccEmail VARCHAR(500) NULL,

    EmailSubject VARCHAR(300) NOT NULL,
    EmailBody NVARCHAR(MAX) NOT NULL,

    MailStatus TINYINT NOT NULL DEFAULT 0,
        -- 0 = Pending
        -- 1 = Sent
        -- 2 = Failed

    ErrorMessage NVARCHAR(1000) NULL,

    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    SentAt DATETIME NULL,
    RetryCount TINYINT NOT NULL DEFAULT 0
);


CREATE INDEX IX_MailLog_Status
ON dbo.MailLog (MailStatus, CreatedAt);

CREATE PROCEDURE dbo.usp_MailLog_Add
(
    @ModuleName     VARCHAR(50),
    @ReferenceID    INT,
    @ToEmail        VARCHAR(500),
    @CcEmail        VARCHAR(500) = NULL,
    @BccEmail       VARCHAR(500) = NULL,
    @EmailSubject   VARCHAR(300),
    @EmailBody      NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.MailLog
    (
        ModuleName,
        ReferenceID,
        ToEmail,
        CcEmail,
        BccEmail,
        EmailSubject,
        EmailBody,
        MailStatus,
        CreatedAt
    )
    VALUES
    (
        @ModuleName,
        @ReferenceID,
        @ToEmail,
        @CcEmail,
        @BccEmail,
        @EmailSubject,
        @EmailBody,
        0,              -- Pending
        GETDATE()
    );

    -- Return inserted MailLogID
    SELECT SCOPE_IDENTITY() AS MailLogID;
END;
GO

CREATE PROCEDURE dbo.usp_Vendor_Approve
(
    @VendorID INT,
	@TenantID INT,
    @ApproverUserName NVARCHAR(100),
	@IsPublish INT,  -- 1 for approve, 0 for not approve
    @Remarks VARCHAR(500) = NULL  -- optional
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update VendorMaster after approval
    UPDATE dbo.VendorMaster
    SET
        approved_at = GETDATE(),
        approved_by = @ApproverUserName,
        IsPublish = @IsPublish,
        approval_remarks = @Remarks,
        updated_at = GETDATE()
    WHERE VendorID = @VendorID AND TenantID=@TenantID;

    -- Return updated row info (optional)
    SELECT
        VendorID,
        VendorCode,
        business_name,
        approved_at,
        approved_by,
        IsPublish
    FROM dbo.VendorMaster
    WHERE VendorID = @VendorID AND TenantID=@TenantID;
END;
GO


----------Approver Table----------------
CREATE TABLE dbo.ApproverMaster
(
    Id   INT IDENTITY(1,1),
	BranchCode  VARCHAR(50), 
    ApproverID   VARCHAR(50),   
    EmailId    VARCHAR(100),
	IsActive BIT Default 1
    PRIMARY KEY (Id)
);

CREATE PROCEDURE dbo.usp_ApproverMaster_GetByBranchCode
(
    @BranchCode VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        BranchCode,
        ApproverID,
        EmailId
    FROM dbo.ApproverMaster
    WHERE BranchCode = @BranchCode
      AND IsActive = 1
    ORDER BY Id;
END;
GO
-----------------------Hotel Registration----------------------------------
CREATE TABLE propertyType (
    propertyType_id INT IDENTITY(1,1) NOT NULL,
    propertyType VARCHAR(100) UNIQUE NOT NULL
);


CREATE PROC usp_PropertyType_Insert
    @propertyType VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM propertyType WHERE propertyType = @propertyType)
    BEGIN
        SELECT 0 AS Status, 'Property Type already exists' AS Message;
        RETURN;
    END

    INSERT INTO propertyType (propertyType)
    VALUES (@propertyType);

    SELECT 1 AS Status, 'Property Type inserted successfully' AS Message;
END;

CREATE PROC usp_PropertyType_Update
    @propertyType_id INT,
    @propertyType VARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM propertyType 
        WHERE propertyType = @propertyType 
        AND propertyType_id <> @propertyType_id
    )
    BEGIN
        SELECT 0 AS Status, 'Property Type already exists' AS Message;
        RETURN;
    END

    UPDATE propertyType
    SET propertyType = @propertyType
    WHERE propertyType_id = @propertyType_id;

    SELECT 1 AS Status, 'Property Type updated successfully' AS Message;
END;

CREATE PROC usp_PropertyType_GetAll
AS
BEGIN
    SELECT 
        propertyType_id,
        propertyType
    FROM propertyType
    ORDER BY propertyType;
END;

CREATE PROC usp_PropertyType_GetById
    @propertyType_id INT
AS
BEGIN
    SELECT 
        propertyType_id,
        propertyType
    FROM propertyType
    WHERE propertyType_id = @propertyType_id;
END;


CREATE TABLE chainStandalone (
    chainstand_id INT IDENTITY(1,1) NOT NULL,
    chainStandalone VARCHAR(50) UNIQUE NOT NULL
);

CREATE PROC usp_ChainStandalone_Insert
    @chainStandalone VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM chainStandalone WHERE chainStandalone = @chainStandalone)
    BEGIN
        SELECT 0 AS Status, 'Chain/Standalone already exists' AS Message;
        RETURN;
    END

    INSERT INTO chainStandalone (chainStandalone)
    VALUES (@chainStandalone);

    SELECT 1 AS Status, 'Chain/Standalone inserted successfully' AS Message;
END;

CREATE PROC usp_ChainStandalone_Update
    @chainstand_id INT,
    @chainStandalone VARCHAR(50)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM chainStandalone 
        WHERE chainStandalone = @chainStandalone
        AND chainstand_id <> @chainstand_id
    )
    BEGIN
        SELECT 0 AS Status, 'Chain/Standalone already exists' AS Message;
        RETURN;
    END

    UPDATE chainStandalone
    SET chainStandalone = @chainStandalone
    WHERE chainstand_id = @chainstand_id;

    SELECT 1 AS Status, 'Chain/Standalone updated successfully' AS Message;
END;

CREATE PROC usp_ChainStandalone_GetAll
AS
BEGIN
    SELECT 
        chainstand_id,
        chainStandalone
    FROM chainStandalone
    ORDER BY chainStandalone;
END;

CREATE PROC usp_ChainStandalone_GetById
    @chainstand_id INT
AS
BEGIN
    SELECT 
        chainstand_id,
        chainStandalone
    FROM chainStandalone
    WHERE chainstand_id = @chainstand_id;
END;



CREATE TABLE starRating (
    starRating_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    starRating VARCHAR(50) UNIQUE NOT NULL
);

CREATE PROC usp_StarRating_Insert
    @starRating VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM starRating WHERE starRating = @starRating)
    BEGIN
        SELECT 0 AS Status, 'Star Rating already exists' AS Message;
        RETURN;
    END

    INSERT INTO starRating (starRating)
    VALUES (@starRating);

    SELECT 1 AS Status, 'Star Rating inserted successfully' AS Message;
END;

CREATE PROC usp_StarRating_Update
    @starRating_id INT,
    @starRating VARCHAR(50)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM starRating 
        WHERE starRating = @starRating
        AND starRating_id <> @starRating_id
    )
    BEGIN
        SELECT 0 AS Status, 'Star Rating already exists' AS Message;
        RETURN;
    END

    UPDATE starRating
    SET starRating = @starRating
    WHERE starRating_id = @starRating_id;

    SELECT 1 AS Status, 'Star Rating updated successfully' AS Message;
END;

CREATE PROC usp_StarRating_GetAll
AS
BEGIN
    SELECT 
        starRating_id,
        starRating
    FROM starRating
    ORDER BY starRating;
END;

CREATE PROC usp_StarRating_GetById
    @starRating_id INT
AS
BEGIN
    SELECT 
        starRating_id,
        starRating
    FROM starRating
    WHERE starRating_id = @starRating_id;
END;
GO
CREATE TABLE dbo.PriceRange (
    PriceRangeID INT IDENTITY(1,1) PRIMARY KEY,
    MinPrice DECIMAL(10,2) NOT NULL,
    MaxPrice DECIMAL(10,2) NOT NULL,
    DisplayLabel VARCHAR(50) NOT NULL,  -- e.g. '₹1,000 – ₹2,000'
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO


CREATE TABLE hotelsMaster (
    hotel_id BIGINT identity(1,1) PRIMARY KEY,
	TenantID        INT NOT NULL,
	hotel_code VARCHAR(255) NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    propertyType_id INT NOT NULL,
    starRating_id INT NOT NULL,

    owner_name VARCHAR(255) NOT NULL,
    owner_phone VARCHAR(20) NOT NULL,

    chainstand_id INT NOT NULL,

    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),

    city INT NOT NULL,
    state INT NOT NULL,
    country INT NOT NULL,
    pin_code VARCHAR(15) NOT NULL,

    landmark VARCHAR(255),

    year_of_construction INT NOT NULL,
    number_of_floors INT CHECK (number_of_floors >= 0),
    number_of_rooms INT CHECK (number_of_rooms >= 0),

    check_in_time TIME NOT NULL,
    check_out_time TIME NOT NULL,

    how_to_reach TEXT,

    google_map_link VARCHAR(500),
	google_hotel_link VARCHAR(500),
	trip_advisor_link VARCHAR(500),
	distance_from_airport VARCHAR(100),
	distance_from_railway VARCHAR(100),
	distance_from_isbt VARCHAR(100),

    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL,
	updated_at DATETIME NULL ,
    updated_by      NVARCHAR(100) NULL,
	approved_at DATETIME NULL,
    approved_by      NVARCHAR(100) NULL,
	IsPublish BIT NOT NULL DEFAULT 0,
	IsDraft BIT NOT NULL DEFAULT 1,
	approval_remarks NVARCHAR(1000) NULL,
	Isdelete BIT NOT NULL DEFAULT 0
);
CREATE INDEX idx_hotelsMastercity ON hotelsMaster(city);
CREATE INDEX idx_hotelsMasterstate ON hotelsMaster(state);
CREATE INDEX idx_hotelsMasterstar_rating ON hotelsMaster(starRating_id);



CREATE PROC usp_HotelsMaster_Get
@TenantID INT NULL,
    @hotel_name VARCHAR(255) = NULL  -- Optional filter
	
AS
BEGIN
    SELECT 
        hotel_id,
        hotel_code,
        hotel_name        
    FROM hotelsMaster
    WHERE (@hotel_name IS NULL OR hotel_name LIKE '%' + @hotel_name + '%')
	AND TenantID=@TenantID
    ORDER BY hotel_name;
END;



-- Save General Details----------
ALTER PROCEDURE sp_SaveHotelMaster
(
    -- Primary Key (for update)
    @hotel_id BIGINT = NULL,
    @TenantID INT NULL,
    @hotel_name VARCHAR(255),
    @propertyType_id INT,
    @starRating_id INT,
    @owner_name VARCHAR(255),
    @owner_phone VARCHAR(20),
    @chainstand_id INT,
    @address_line1 VARCHAR(255),
    @address_line2 VARCHAR(255) = NULL,
    @city INT,
    @state INT,
    @country INT,
    @pin_code VARCHAR(15),
    @landmark VARCHAR(255) = NULL,
    @year_of_construction INT,
    @number_of_floors INT = 0,
    @number_of_rooms INT = 0,
    @check_in_time TIME,
    @check_out_time TIME,
    @how_to_reach TEXT = NULL,
    @google_map_link VARCHAR(500) = NULL,

    -- Audit & Status
    @user NVARCHAR(100),
    @IsPublish BIT = 0,
    @IsDraft BIT = 1,
    @approval_remarks NVARCHAR(1000) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validation Checks
    IF @number_of_floors < 0
    BEGIN
        RAISERROR('Number of floors cannot be negative.', 16, 1);
        RETURN;
    END

    IF @number_of_rooms < 0
    BEGIN
        RAISERROR('Number of rooms cannot be negative.', 16, 1);
        RETURN;
    END

    -- Duplicate check (only for insert)
    IF @hotel_id IS NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM hotelsMaster 
            WHERE hotel_name = @hotel_name AND TenantID = @TenantID 
        )
        BEGIN
            RAISERROR('Duplicate hotel name exists for this tenant.', 16, 1);
            RETURN;
        END

        -- INSERT (hotel_code will be generated AFTER insert)
        INSERT INTO hotelsMaster
        (
            hotel_name, propertyType_id, starRating_id,
            owner_name, owner_phone, chainstand_id,
            address_line1, address_line2, city, state, country, pin_code, landmark,
            year_of_construction, number_of_floors, number_of_rooms,
            check_in_time, check_out_time, how_to_reach, google_map_link,
            created_at, created_by, IsPublish, IsDraft, approval_remarks, TenantID
        )
        VALUES
        (
            @hotel_name, @propertyType_id, @starRating_id,
            @owner_name, @owner_phone, @chainstand_id,
            @address_line1, @address_line2, @city, @state, @country, @pin_code, @landmark,
            @year_of_construction, @number_of_floors, @number_of_rooms,
            @check_in_time, @check_out_time, @how_to_reach, @google_map_link,
            GETDATE(), @user, @IsPublish, @IsDraft, @approval_remarks, @TenantID
        );

        -- Get newly inserted hotel_id
        DECLARE @NewHotelID BIGINT = SCOPE_IDENTITY();

        -- Generate hotel_code as 'HM' + 6-digit ID
        UPDATE hotelsMaster
        SET hotel_code = 'HM' + RIGHT('000000' + CAST(@NewHotelID AS VARCHAR(6)), 6)
        WHERE hotel_id = @NewHotelID;

        SELECT @NewHotelID AS hotel_id, 
               'HM' + RIGHT('000000' + CAST(@NewHotelID AS VARCHAR(6)), 6) AS hotel_code;
    END
    ELSE
    BEGIN
        -- UPDATE
        UPDATE hotelsMaster
        SET 
            hotel_name = @hotel_name,
            propertyType_id = @propertyType_id,
            starRating_id = @starRating_id,
            owner_name = @owner_name,
            owner_phone = @owner_phone,
            chainstand_id = @chainstand_id,
            address_line1 = @address_line1,
            address_line2 = @address_line2,
            city = @city,
            state = @state,
            country = @country,
            pin_code = @pin_code,
            landmark = @landmark,
            year_of_construction = @year_of_construction,
            number_of_floors = @number_of_floors,
            number_of_rooms = @number_of_rooms,
            check_in_time = @check_in_time,
            check_out_time = @check_out_time,
            how_to_reach = @how_to_reach,
            google_map_link = @google_map_link,
            updated_at = GETDATE(),
            updated_by = @user,
            IsPublish = @IsPublish,
            IsDraft = @IsDraft,
            approval_remarks = @approval_remarks
        WHERE hotel_id = @hotel_id AND TenantID = @TenantID;

        SELECT @hotel_id AS hotel_id,
               hotel_code
        FROM hotelsMaster
        WHERE hotel_id = @hotel_id AND TenantID = @TenantID;
    END
END
GO



CREATE TABLE dbo.vegNonveg (
    veg_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    vegname VARCHAR(50) UNIQUE NOT NULL
);

CREATE PROC usp_VegNonveg_Insert
    @vegname VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM vegNonveg WHERE vegname = @vegname)
    BEGIN
        SELECT 0 AS Status, 'Veg/Non-Veg already exists' AS Message;
        RETURN;
    END

    INSERT INTO vegNonveg (vegname)
    VALUES (@vegname);

    SELECT 1 AS Status, 'Veg/Non-Veg inserted successfully' AS Message;
END;

CREATE PROC usp_VegNonveg_Update
    @veg_id INT,
    @vegname VARCHAR(50)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM vegNonveg 
        WHERE vegname = @vegname 
        AND veg_id <> @veg_id
    )
    BEGIN
        SELECT 0 AS Status, 'Veg/Non-Veg already exists' AS Message;
        RETURN;
    END

    UPDATE vegNonveg
    SET vegname = @vegname
    WHERE veg_id = @veg_id;

    SELECT 1 AS Status, 'Veg/Non-Veg updated successfully' AS Message;
END;

CREATE PROC usp_VegNonveg_GetAll
AS
BEGIN
    SELECT 
        veg_id,
        vegname
    FROM vegNonveg
    ORDER BY vegname;
END;

CREATE PROC usp_VegNonveg_GetById
    @veg_id INT
AS
BEGIN
    SELECT 
        veg_id,
        vegname
    FROM vegNonveg
    WHERE veg_id = @veg_id;
END;

CREATE TABLE dbo.cuisine (
    cuisine_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    cuisinename VARCHAR(50) UNIQUE NOT NULL
);

CREATE PROC usp_Cuisine_Insert
    @cuisinename VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM cuisine WHERE cuisinename = @cuisinename)
    BEGIN
        SELECT 0 AS Status, 'Cuisine already exists' AS Message;
        RETURN;
    END

    INSERT INTO cuisine (cuisinename)
    VALUES (@cuisinename);

    SELECT 1 AS Status, 'Cuisine inserted successfully' AS Message;
END;

CREATE PROC usp_Cuisine_Update
    @cuisine_id INT,
    @cuisinename VARCHAR(50)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM cuisine 
        WHERE cuisinename = @cuisinename
        AND cuisine_id <> @cuisine_id
    )
    BEGIN
        SELECT 0 AS Status, 'Cuisine already exists' AS Message;
        RETURN;
    END

    UPDATE cuisine
    SET cuisinename = @cuisinename
    WHERE cuisine_id = @cuisine_id;

    SELECT 1 AS Status, 'Cuisine updated successfully' AS Message;
END;

CREATE PROC usp_Cuisine_GetAll
AS
BEGIN
    SELECT 
        cuisine_id,
        cuisinename
    FROM cuisine
    ORDER BY cuisinename;
END;

CREATE PROC usp_Cuisine_GetById
    @cuisine_id INT
AS
BEGIN
    SELECT 
        cuisine_id,
        cuisinename
    FROM cuisine
    WHERE cuisine_id = @cuisine_id;
END;


CREATE TABLE dbo.restaurantsOnProperty (
    resta_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    hotel_id BIGINT NOT NULL,
    resta_name VARCHAR(255) NOT NULL,
    veg_id INT NOT NULL,
    cuisine_id INT NOT NULL,
    no_of_covers INT NOT NULL CHECK (no_of_covers >= 0),
    in_room_dining_facility BIT NOT NULL,
	IsDeleted INT
);


CREATE PROC usp_RestaurantsOnProperty_Insert
    @hotel_id BIGINT,
    @resta_name VARCHAR(255),
    @veg_id INT,
    @cuisine_id INT,
    @no_of_covers INT,
    @in_room_dining_facility BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM restaurantsOnProperty
        WHERE hotel_id = @hotel_id
          AND resta_name = @resta_name
          AND ISNULL(IsDeleted,0) = 0
    )
    BEGIN
        SELECT 0 AS Status, 'Restaurant already exists for this hotel' AS Message;
        RETURN;
    END

    INSERT INTO restaurantsOnProperty
    (hotel_id, resta_name, veg_id, cuisine_id, no_of_covers, in_room_dining_facility, IsDeleted)
    VALUES
    (@hotel_id, @resta_name, @veg_id, @cuisine_id, @no_of_covers, @in_room_dining_facility, 0);

    SELECT 1 AS Status, 'Restaurant added successfully' AS Message;
END;

CREATE PROC usp_RestaurantsOnProperty_Update
    @resta_id BIGINT,
    @hotel_id BIGINT,
    @resta_name VARCHAR(255),
    @veg_id INT,
    @cuisine_id INT,
    @no_of_covers INT,
    @in_room_dining_facility BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM restaurantsOnProperty
        WHERE hotel_id = @hotel_id
          AND resta_name = @resta_name
          AND resta_id <> @resta_id
          AND ISNULL(IsDeleted,0) = 0
    )
    BEGIN
        SELECT 0 AS Status, 'Restaurant already exists for this hotel' AS Message;
        RETURN;
    END

    UPDATE restaurantsOnProperty
    SET resta_name = @resta_name,
        veg_id = @veg_id,
        cuisine_id = @cuisine_id,
        no_of_covers = @no_of_covers,
        in_room_dining_facility = @in_room_dining_facility
    WHERE resta_id = @resta_id;

    SELECT 1 AS Status, 'Restaurant updated successfully' AS Message;
END;

CREATE PROC usp_RestaurantsOnProperty_Delete
    @resta_id BIGINT
AS
BEGIN
    UPDATE restaurantsOnProperty
    SET IsDeleted = 1
    WHERE resta_id = @resta_id;

    SELECT 1 AS Status, 'Restaurant deleted successfully' AS Message;
END;

------------Contact details---------------------------

CREATE TABLE hotelscontacts (
    contact_id BIGINT identity(1,1) PRIMARY KEY ,
	hotel_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    designation VARCHAR(100),
    landline_country_code VARCHAR(10),
    landline_number VARCHAR(20),
    whatsapp_country_code VARCHAR(10),
    whatsapp_number VARCHAR(20),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL,
	updated_at DATETIME NULL ,
    updated_by      NVARCHAR(100) NULL,
	isdeleted INT NULL
);

CREATE PROC usp_HotelsContacts_Insert
    @name VARCHAR(100),
	@hotel_id BIGINT NULL,
    @department VARCHAR(100),
    @designation VARCHAR(100),
    @landline_country_code VARCHAR(10),
    @landline_number VARCHAR(20),
    @whatsapp_country_code VARCHAR(10),
    @whatsapp_number VARCHAR(20),
    @created_by NVARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM hotelscontacts
        WHERE name = @name
          AND ISNULL(department,'') = ISNULL(@department,'')
          AND ISNULL(designation,'') = ISNULL(@designation,'')
          AND ISNULL(hotel_id,0) = @hotel_id
    )
    BEGIN
        SELECT 0 AS Status, 'Contact already exists' AS Message;
        RETURN;
    END

    INSERT INTO hotelscontacts
    (name, department, designation, landline_country_code, landline_number,
     whatsapp_country_code, whatsapp_number, created_by, isdeleted,hotel_id)
    VALUES
    (@name, @department, @designation, @landline_country_code, @landline_number,
     @whatsapp_country_code, @whatsapp_number, @created_by, 0,@hotel_id);

    SELECT 1 AS Status, 'Contact added successfully' AS Message;
END;

CREATE PROC usp_HotelsContacts_Update
    @contact_id BIGINT,

    @name VARCHAR(100),
    @department VARCHAR(100),
    @designation VARCHAR(100),
    @landline_country_code VARCHAR(10),
    @landline_number VARCHAR(20),
    @whatsapp_country_code VARCHAR(10),
    @whatsapp_number VARCHAR(20),
    @updated_by NVARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM hotelscontacts
        WHERE name = @name
          AND ISNULL(department,'') = ISNULL(@department,'')
          AND ISNULL(designation,'') = ISNULL(@designation,'')
          AND contact_id <> @contact_id
         
    )
    BEGIN
        SELECT 0 AS Status, 'Contact already exists' AS Message;
        RETURN;
    END

    UPDATE hotelscontacts
    SET name = @name,
        department = @department,
        designation = @designation,
        landline_country_code = @landline_country_code,
        landline_number = @landline_number,
        whatsapp_country_code = @whatsapp_country_code,
        whatsapp_number = @whatsapp_number,
        updated_at = GETDATE(),
        updated_by = @updated_by
    WHERE contact_id = @contact_id;

    SELECT 1 AS Status, 'Contact updated successfully' AS Message;
END;

CREATE PROC usp_HotelsContacts_Delete
    @contact_id BIGINT
AS
BEGIN
    UPDATE hotelscontacts
    SET isdeleted = 1
    WHERE contact_id = @contact_id;

    SELECT 1 AS Status, 'Contact deleted successfully' AS Message;
END;



CREATE TABLE phonetype (
    phonetype_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    phonetype VARCHAR(50) UNIQUE NOT NULL   --'mobile','alternate','phone'
);
CREATE PROC usp_Phonetype_Insert
    @phonetype VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM phonetype WHERE phonetype = @phonetype)
    BEGIN
        SELECT 0 AS Status, 'Phone type already exists' AS Message;
        RETURN;
    END

    INSERT INTO phonetype (phonetype)
    VALUES (@phonetype);

    SELECT 1 AS Status, 'Phone type inserted successfully' AS Message;
END;

CREATE PROC usp_Phonetype_GetAll
AS
BEGIN
    SELECT 
        phonetype_id,
        phonetype
    FROM phonetype
    ORDER BY phonetype;
END;

CREATE PROC usp_Phonetype_GetById
    @phonetype_id INT
AS
BEGIN
    SELECT 
        phonetype_id,
        phonetype
    FROM phonetype
    WHERE phonetype_id = @phonetype_id;
END;


CREATE TABLE hotelscontact_phone_numbers (
    phone_id BIGINT identity(1,1) PRIMARY KEY ,
    contact_id BIGINT NOT NULL,
    country_code VARCHAR(10),
    phone_number VARCHAR(20) NOT NULL,
    phonetype_id INT, --'mobile','alternate'
	created_at DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL
    FOREIGN KEY (contact_id) REFERENCES hotelscontacts(contact_id) ON DELETE CASCADE
);

CREATE PROC usp_HotelsContactPhone_Insert
    @contact_id BIGINT,
    @country_code VARCHAR(10),
    @phone_number VARCHAR(20),
    @phonetype_id INT,
    @created_by NVARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM hotelscontact_phone_numbers
        WHERE contact_id = @contact_id
          AND phone_number = @phone_number
    )
    BEGIN
        SELECT 0 AS Status, 'Phone number already exists' AS Message;
        RETURN;
    END

    INSERT INTO hotelscontact_phone_numbers
    (contact_id, country_code, phone_number, phonetype_id, created_by)
    VALUES
    (@contact_id, @country_code, @phone_number, @phonetype_id, @created_by);

    SELECT 1 AS Status, 'Phone number added successfully' AS Message;
END;

CREATE PROC usp_HotelsContactPhone_Delete
    @phone_id BIGINT
AS
BEGIN
    DELETE FROM hotelscontact_phone_numbers
    WHERE phone_id = @phone_id;

    SELECT 1 AS Status, 'Phone number deleted successfully' AS Message;
END;


CREATE TABLE hotelscontact_emails (
    email_id BIGINT identity(1,1) PRIMARY KEY ,
    contact_id BIGINT NOT NULL,
    email VARCHAR(150) NOT NULL,
	created_at DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL
    FOREIGN KEY (contact_id) REFERENCES hotelscontacts(contact_id) ON DELETE CASCADE
);

CREATE PROC usp_HotelsContactEmail_Insert
    @contact_id BIGINT,
    @email VARCHAR(150),
    @created_by NVARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM hotelscontact_emails
        WHERE contact_id = @contact_id
          AND email = @email
    )
    BEGIN
        SELECT 0 AS Status, 'Email already exists' AS Message;
        RETURN;
    END

    INSERT INTO hotelscontact_emails
    (contact_id, email, created_by)
    VALUES
    (@contact_id, @email, @created_by);

    SELECT 1 AS Status, 'Email added successfully' AS Message;
END;

CREATE PROC usp_HotelsContactEmail_Delete
    @email_id BIGINT
AS
BEGIN
    DELETE FROM hotelscontact_emails
    WHERE email_id = @email_id;

    SELECT 1 AS Status, 'Email deleted successfully' AS Message;
END;

--------------hotel Facilities--------------------

CREATE TABLE dbo.HotelAmenities (
    AmenityID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    AmenityName VARCHAR(100) UNIQUE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);
CREATE INDEX idx_HotelAmenities ON HotelAmenities(AmenityID);
CREATE OR ALTER PROC usp_HotelAmenities_Insert
    @AmenityName VARCHAR(100),
    @SortOrder INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM HotelAmenities 
        WHERE AmenityName = @AmenityName
    )
    BEGIN
        SELECT 0 AS Status, 'Amenity already exists' AS Message;
        RETURN;
    END

    INSERT INTO HotelAmenities (AmenityName, SortOrder)
    VALUES (@AmenityName, @SortOrder);

    SELECT 1 AS Status, 'Amenity inserted successfully' AS Message;
END;
CREATE OR ALTER PROC usp_HotelAmenities_Update
    @AmenityID INT,
    @AmenityName VARCHAR(100),
    @SortOrder INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM HotelAmenities 
        WHERE AmenityName = @AmenityName
        AND AmenityID <> @AmenityID
    )
    BEGIN
        SELECT 0 AS Status, 'Amenity already exists' AS Message;
        RETURN;
    END

    UPDATE HotelAmenities
    SET AmenityName = @AmenityName,
        SortOrder = @SortOrder
    WHERE AmenityID = @AmenityID;

    SELECT 1 AS Status, 'Amenity updated successfully' AS Message;
END;
CREATE OR ALTER PROC usp_HotelAmenities_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AmenityID,
        AmenityName,
        SortOrder,
        IsActive,
        CreatedDate
    FROM HotelAmenities
    ORDER BY SortOrder, AmenityName;
END;
CREATE OR ALTER PROC usp_HotelAmenities_GetById
    @AmenityID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AmenityID,
        AmenityName,
        SortOrder,
        IsActive,
        CreatedDate
    FROM HotelAmenities
    WHERE AmenityID = @AmenityID;
END;



CREATE TABLE dbo.hotelFacilities (
	Facilities_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	hotel_id BIGINT NOT NULL,
    AmenityID INT NOT NULL,	
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL
);

CREATE PROC usp_HotelFacilities_Insert
    @hotel_id BIGINT,
    @AmenityID INT,
    @created_by NVARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM hotelFacilities
        WHERE hotel_id = @hotel_id
          AND AmenityID = @AmenityID
    )
    BEGIN
        SELECT 0 AS Status, 'Facility already mapped to hotel' AS Message;
        RETURN;
    END

    INSERT INTO hotelFacilities
    (hotel_id, AmenityID, created_by)
    VALUES
    (@hotel_id, @AmenityID, @created_by);

    SELECT 1 AS Status, 'Facility added successfully' AS Message;
END;
alter PROC usp_HotelFacilities_Delete
    @Facilities_id INT
AS
BEGIN
    DELETE FROM hotelFacilities
    WHERE Facilities_id = @Facilities_id;

    SELECT 1 AS Status, 'Facility removed successfully' AS Message;
END;

---------------save as Draft/Next--------------------
CREATE PROC usp_HotelsMaster_UpdateIsDraft
    @hotel_id BIGINT,
    @IsDraft BIT,
    @updated_by NVARCHAR(100) = NULL
AS
BEGIN
    -- Check if hotel exists
    IF NOT EXISTS (
        SELECT 1 FROM hotelsMaster WHERE hotel_id = @hotel_id
    )
    BEGIN
        SELECT 0 AS Status, 'Hotel not found' AS Message;
        RETURN;
    END

    UPDATE hotelsMaster
    SET IsDraft = @IsDraft,
        updated_at = GETDATE(),
        updated_by = ISNULL(@updated_by, updated_by)
    WHERE hotel_id = @hotel_id;

    SELECT 1 AS Status, 'Draft status updated successfully' AS Message;
END;

-------------------Room Details--------------------------------------------------

CREATE TABLE roomFacilitiesMaster (
	roomFacilities_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	roomFacilities VARCHAR(100) NOT NULL
	);

CREATE PROC usp_RoomFacilitiesMaster_Insert
    @roomFacilities VARCHAR(100)
AS
BEGIN
    -- Check duplicate
    IF EXISTS (SELECT 1 FROM roomFacilitiesMaster WHERE roomFacilities = @roomFacilities)
    BEGIN
        SELECT 0 AS Status, 'Room Facility already exists' AS Message;
        RETURN;
    END

    -- Insert new facility
    INSERT INTO roomFacilitiesMaster (roomFacilities)
    VALUES (@roomFacilities);

    SELECT 1 AS Status, 'Room Facility added successfully' AS Message;
END;

CREATE PROC usp_RoomFacilitiesMaster_Update
    @roomFacilities_id INT,
    @roomFacilities VARCHAR(100)
AS
BEGIN
    -- Check duplicate for other IDs
    IF EXISTS (
        SELECT 1 
        FROM roomFacilitiesMaster
        WHERE roomFacilities = @roomFacilities
          AND roomFacilities_id <> @roomFacilities_id
    )
    BEGIN
        SELECT 0 AS Status, 'Room Facility already exists' AS Message;
        RETURN;
    END

    -- Update facility
    UPDATE roomFacilitiesMaster
    SET roomFacilities = @roomFacilities
    WHERE roomFacilities_id = @roomFacilities_id;

    SELECT 1 AS Status, 'Room Facility updated successfully' AS Message;
END;

CREATE PROC usp_RoomFacilitiesMaster_Delete
    @roomFacilities_id INT
AS
BEGIN
    DELETE FROM roomFacilitiesMaster
    WHERE roomFacilities_id = @roomFacilities_id;

    SELECT 1 AS Status, 'Room Facility deleted successfully' AS Message;
END;


CREATE PROC usp_RoomFacilitiesMaster_Get
 @roomFacilities_name VARCHAR(255) = NULL  -- Optional filter
AS
BEGIN
    SELECT 
        roomFacilities_id,
        roomFacilities
    FROM roomFacilitiesMaster
	  WHERE (@roomFacilities_name IS NULL OR roomFacilities LIKE '%' + @roomFacilities_name + '%')
    ORDER BY roomFacilities;
    
END;


CREATE PROC usp_RoomFacilitiesMaster_GetById
    @roomFacilities_id INT
AS
BEGIN
    SELECT 
        roomFacilities_id,
        roomFacilities
    FROM roomFacilitiesMaster
    WHERE roomFacilities_id = @roomFacilities_id;
END;


CREATE TABLE hotelRooms (
    RoomId INT PRIMARY KEY IDENTITY(1,1),
    hotel_id BIGINT NOT NULL,
    RoomCategoryName NVARCHAR(100) NOT NULL,
    RoomDescription NVARCHAR(500) NULL,
    NoOfBeds INT NOT NULL,
    NoOfRooms INT NOT NULL,
    TwinBedAvailable BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (hotel_id) REFERENCES hotelsMaster(hotel_id)
);

CREATE TABLE hotelRoomMedia (
    RoomMediaId INT PRIMARY KEY IDENTITY(1,1),
    RoomId INT NOT NULL,
    ImageName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    ImagePath NVARCHAR(300) NULL, -- Or store URL if images are stored elsewhere
    FOREIGN KEY (RoomId) REFERENCES hotelRooms(RoomId)
);
select * from hotelRoomAmenities
CREATE TABLE hotelRoomAmenities (
    RoomAmenityId INT PRIMARY KEY IDENTITY(1,1),
    RoomId INT NOT NULL,
    roomFacilities_id INT NOT NULL,
    FOREIGN KEY (RoomId) REFERENCES hotelRooms(RoomId),
    FOREIGN KEY (roomFacilities_id) REFERENCES roomFacilitiesMaster(roomFacilities_id),
    UNIQUE(RoomId, roomFacilities_id)
);

ALTER TABLE hotelRooms ADD IsDeleted BIT NOT NULL DEFAULT 0;
ALTER TABLE hotelRoomMedia ADD IsDeleted BIT NOT NULL DEFAULT 0;
ALTER TABLE hotelRoomAmenities ADD IsDeleted BIT NOT NULL DEFAULT 0;

CREATE PROCEDURE dbo.usp_AddRoom
    @HotelId BIGINT,
    @RoomCategoryName NVARCHAR(100),
    @RoomDescription NVARCHAR(500) = NULL,
    @NoOfBeds INT,
    @NoOfRooms INT,
    @TwinBedAvailable BIT
AS
BEGIN
    -- Check for duplicate RoomCategoryName for same HotelId
    IF EXISTS (
        SELECT 1 FROM hotelRooms
        WHERE hotel_id = @HotelId AND RoomCategoryName = @RoomCategoryName
    )
    BEGIN
        RAISERROR ('Duplicate room category for this hotel.', 16, 1);
        RETURN;
    END

    INSERT INTO hotelRooms (hotel_id, RoomCategoryName, RoomDescription, NoOfBeds, NoOfRooms, TwinBedAvailable)
    VALUES (@HotelId, @RoomCategoryName, @RoomDescription, @NoOfBeds, @NoOfRooms, @TwinBedAvailable);

    SELECT SCOPE_IDENTITY() AS NewRoomId;
END
go;
CREATE PROCEDURE dbo.usp_AddRoomMedia
    @RoomId INT,
    @ImageName NVARCHAR(200),
    @Description NVARCHAR(500),
    @ImageData NVARCHAR(300) = NULL
AS
BEGIN
    -- Check duplicate image name for same RoomId
    IF EXISTS (
        SELECT 1 FROM hotelRoomMedia
        WHERE RoomId = @RoomId AND ImageName = @ImageName
    )
    BEGIN
        RAISERROR ('Duplicate image name for this room.', 16, 1);
        RETURN;
    END

    INSERT INTO hotelRoomMedia (RoomId, ImageName, Description, ImagePath)
    VALUES (@RoomId, @ImageName, @Description, @ImageData);
END
go;

ALTER TABLE hotelRooms
ADD CONSTRAINT UQ_Room_Hotel_Category UNIQUE (hotel_id, RoomCategoryName);

ALTER TABLE hotelRoomMedia
ADD CONSTRAINT UQ_RoomMedia_Room_Image UNIQUE (RoomId, ImageName);

CREATE PROCEDURE SoftDeletehotelRoom
    @RoomId INT
AS
BEGIN
    -- Mark related RoomAmenities as deleted
    UPDATE hotelRoomAmenities
    SET IsDeleted = 1
    WHERE RoomId = @RoomId;

    -- Mark related RoomMedia as deleted
    UPDATE hotelRoomMedia
    SET IsDeleted = 1
    WHERE RoomId = @RoomId;

    -- Mark Room as deleted
    UPDATE hotelRooms
    SET IsDeleted = 1
    WHERE RoomId = @RoomId;
END
go;
CREATE TABLE dbo.RoomCategoryMaster (
    RoomCategoryID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    RoomCategoryName VARCHAR(100) UNIQUE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);
go;

CREATE TABLE dbo.SeasonMaster (
    SeasonID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    SeasonName VARCHAR(100) UNIQUE NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	CreatedBy VARCHAR(50)
);
go;
CREATE TABLE dbo.MealPlanMaster (
    MealPlanID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MealPlanCode VARCHAR(10) UNIQUE NOT NULL,      -- e.g., CPAI, EP, MAP
    MealPlanName VARCHAR(100) UNIQUE NOT NULL,     -- Full description
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);
go;

CREATE TABLE dbo.roomOccupancyMaster (
    occupancy_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    occupancy_name VARCHAR(50) UNIQUE NOT NULL,
    max_adults INT NOT NULL,
    max_children INT NULL,
    description VARCHAR(200) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NULL
);

CREATE TABLE dbo.extraBedTypeMaster (
    extraBedType_id INT IDENTITY(1,1) PRIMARY KEY,
    extraBedTypeCode VARCHAR(10) UNIQUE NOT NULL,
    extraBedTypeName VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    SortOrder INT NULL
);


CREATE TABLE dbo.HotelRateHeader (
    rateHeader_id INT IDENTITY(1,1) PRIMARY KEY,
	hotel_id BIGINT,
	vendorId INT NOT NULL,
    SeasonID INT NOT NULL,
    RoomCategoryID INT NOT NULL,
    MealPlanID INT NOT NULL,
    vendor_id INT NOT NULL,

    currency VARCHAR(10) DEFAULT 'INR',
    IsActive BIT NOT NULL DEFAULT 1,

    CreatedBy VARCHAR(30) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(30) NULL,
    ModifiedDate DATETIME NULL,
	ApprovedBy VARCHAR(30) NULL,
    ApprovedDate DATETIME NULL
);

CREATE TABLE dbo.HotelRateDetail (
    rateDetail_id INT IDENTITY(1,1) PRIMARY KEY,

    rateHeader_id INT NOT NULL,
    occupancy_id INT NOT NULL,       -- Single / Double / Triple
    extraBedType_id INT NULL,         -- NULL = base room price

    netPrice DECIMAL(10,2) NOT NULL,
    markupPrice DECIMAL(10,2) NOT NULL,
    sellingPrice AS (netPrice + markupPrice) PERSISTED,

    IsActive BIT NOT NULL DEFAULT 1
);
