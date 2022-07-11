BEGIN TRANSACTION;
    CREATE TABLE trusted_hosts (
        mac_address TEXT NOT NULL,
        ip_address TEXT NOT NULL,
        PRIMARY KEY(ip_address)
    );
COMMIT;
