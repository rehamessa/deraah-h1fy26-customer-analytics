USE Deraah_SDA;
GO

CREATE INDEX ix_fct_customer_key ON marts.fct_sales_lines(customer_key);
CREATE INDEX ix_fct_date_key ON marts.fct_sales_lines(date_key);