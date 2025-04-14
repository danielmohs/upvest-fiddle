{% macro get_shares_bought_by_customer(credit_account_description, credit_amount) %}
    CASE WHEN {{ credit_account_description }} = 'customer_account' THEN {{ credit_amount }} ELSE 0 END
{% endmacro %}


{% macro get_shares_sold_by_customer(debit_account_description, debit_amount) %}
    CASE WHEN {{ debit_account_description }} = 'customer_account' THEN {{ debit_amount }} ELSE 0 END
{% endmacro %}
