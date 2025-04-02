import pandas as pd
import pandera as pa

# Define schema using functional API
sample1_schema = pa.DataFrameSchema(
    {
        "id": pa.Column(int, checks=pa.Check.gt(0)),
        "name": pa.Column(str),
        "age": pa.Column(int, checks=[pa.Check.ge(0), pa.Check.le(120)]),
        "score": pa.Column(float, checks=[pa.Check.ge(0), pa.Check.le(100)]),
    },
    strict=True,  # Equivalent to SchemaConfig strict
    coerce=True,  # Equivalent to SchemaConfig coerce
    name="Sample1Schema",  # Optional: Give the schema a name for better error messages
)


# Keep the validation function, but use the functional schema
# The @pa.check_types decorator might need adjustment or removal if it causes issues
# with the functional schema approach, but let's try keeping it first.
@pa.check_types
def validate_sample1_data(
    df: pd.DataFrame,
) -> pd.DataFrame:  # Adjusted return type hint
    """Sample1データの検証"""
    # Validate using the functional schema instance
    return sample1_schema.validate(df)
