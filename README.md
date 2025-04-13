# Upvest Analytics Engineering Case Study

This dbt project was created as part of the Upvest Analytics Engineering challenge. It demonstrates the ability to design, structure, and implement a scalable and well-documented dbt pipeline using BigQuery, with a focus on maintainability, testing, and business relevance.

## Project Overview

This project models securities transaction data from a financial ledger system, transforming raw transaction records into business-ready analytics models. The pipeline processes securities movements, handles corrections, and provides aggregated views for both customer-facing and internal operational analytics.

## Data Architecture

The project follows the medallion architecture pattern with three main layers:

- **Staging**: Raw data ingestion with minimal transformations
- **Intermediate**: Business logic implementation, including correction handling
- **Mart**: Business-ready aggregated models for analytics consumption

## Key Models

- `customer_asset_summary`: Provides customer-level insights on securities transactions
- `securities_flow_summary`: Aggregates platform-wide securities movements for operational reporting
- `int_ledger_corrected`: Processes enriched ledger data and handles booking corrections

## Testing

The project includes various tests to ensure data quality:
- Uniqueness constraints on primary keys
- Not-null constraints on required fields
- Referential integrity checks
- Custom data quality tests


## Author

**Daniel Mohs**  
Analytics Engineering Challenge — April 2025
