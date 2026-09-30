-- =====================================================================
-- 00_schema.sql  --  CS 284/430 Project 1: Chicago North Side Car Repair DB
-- Creates the dedicated database and the five core tables.
-- Re-running this script is the documented reset: it drops and rebuilds
-- ONLY the project database `p1_car_repair`.
--
-- Business rules enforced here:
--   BR1 (identity)      Each business is one licensed shop at ONE selected
--                       physical location; (business_name, street_address)
--                       is unique.
--   BR2 (relationships) Every service belongs to exactly one category; a
--                       business may offer many services and a service may be
--                       offered by many businesses (business_service).
--   BR3 (required)      Every business and every offering must cite a Source
--                       and a raw-row reference; name, address, and city are
--                       required. Website is optional (NULL = none recorded).
--   BR4 (duplicates)    A business-service pair can be recorded only once
--                       (composite primary key), regardless of how many pages
--                       mention it.
--
-- Deletion behavior:
--   * Deleting a business cascades to its offerings (an offering has no
--     meaning without its business).
--   * Services, categories, and sources are RESTRICTed: you cannot delete a
--     category that still has services, a service that is still offered, or
--     a source that is still cited.
-- =====================================================================

DROP DATABASE IF EXISTS p1_car_repair;
CREATE DATABASE p1_car_repair CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE p1_car_repair;

SET FOREIGN_KEY_CHECKS = 1;

-- One row per cited page or dataset (the source register).
CREATE TABLE source (
    source_id        VARCHAR(10)   NOT NULL,             -- e.g. 'SRC01', matches data/source_register.csv
    publisher        VARCHAR(100)  NOT NULL,             -- organization that published the page/dataset
    title            VARCHAR(255)  NOT NULL,             -- page or dataset title
    url              VARCHAR(500)  NOT NULL,             -- exact URL visited
    collection_date  DATE          NOT NULL,             -- date the page was accessed
    raw_file         VARCHAR(255)  NOT NULL,             -- locator of the saved copy in the ZIP
    CONSTRAINT pk_source PRIMARY KEY (source_id),
    CONSTRAINT uq_source_url UNIQUE (url)
) ENGINE = InnoDB;

-- Service categories (one side of the 1:N with service).
CREATE TABLE service_category (
    category_id    TINYINT UNSIGNED NOT NULL,
    category_name  VARCHAR(50)      NOT NULL,
    CONSTRAINT pk_service_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
) ENGINE = InnoDB;

-- Standardized service types; each belongs to exactly one category.
CREATE TABLE service (
    service_id    TINYINT UNSIGNED NOT NULL,
    service_name  VARCHAR(50)      NOT NULL,
    category_id   TINYINT UNSIGNED NOT NULL,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT uq_service_name UNIQUE (service_name),
    CONSTRAINT fk_service_category FOREIGN KEY (category_id)
        REFERENCES service_category (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- One selected physical location per business (branch subsystem out of scope).
CREATE TABLE business (
    business_id     SMALLINT UNSIGNED NOT NULL,
    business_name   VARCHAR(100)      NOT NULL,
    street_address  VARCHAR(100)      NOT NULL,          -- the selected location
    city            VARCHAR(50)       NOT NULL,
    state           CHAR(2)           NOT NULL,
    zip_code        CHAR(5)           NOT NULL,
    neighborhood    VARCHAR(50)       NULL,              -- Chicago community area from the license record
    website         VARCHAR(255)      NULL,              -- NULL = no working website recorded
    source_id       VARCHAR(10)       NOT NULL,          -- source supporting identity + location
    raw_row_ref     VARCHAR(40)       NOT NULL,          -- e.g. 'LIC:<license row id>' in the raw CSV
    CONSTRAINT pk_business PRIMARY KEY (business_id),
    CONSTRAINT uq_business_location UNIQUE (business_name, street_address),
    CONSTRAINT fk_business_source FOREIGN KEY (source_id)
        REFERENCES source (source_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Associative table resolving business <-> service (M:N).
CREATE TABLE business_service (
    business_id       SMALLINT UNSIGNED NOT NULL,
    service_id        TINYINT UNSIGNED  NOT NULL,
    source_id         VARCHAR(10)       NOT NULL,        -- source supporting this offering
    raw_row_ref       VARCHAR(40)       NOT NULL,        -- e.g. 'OBS:OBS009' in manual_observations.csv
    observed_wording  VARCHAR(255)      NOT NULL,        -- service text exactly as observed
    CONSTRAINT pk_business_service PRIMARY KEY (business_id, service_id),
    CONSTRAINT fk_bs_business FOREIGN KEY (business_id)
        REFERENCES business (business_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bs_service FOREIGN KEY (service_id)
        REFERENCES service (service_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bs_source FOREIGN KEY (source_id)
        REFERENCES source (source_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;
