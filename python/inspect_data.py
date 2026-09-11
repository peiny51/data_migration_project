import pandas as pd

df = pd.read_csv("data/legacy_customers.csv")

# print(df)
print(
    df["customer_id"]
    .value_counts()
)