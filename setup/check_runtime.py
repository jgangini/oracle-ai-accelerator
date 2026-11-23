import numpy as np
import pandas as pd
import pyarrow as pa
from streamlit.dataframe_util import convert_pandas_df_to_arrow_bytes


if __name__ == "__main__":
    frame = pd.DataFrame({"value": np.array([1, 2, 3])})
    encoded = convert_pandas_df_to_arrow_bytes(frame)
    restored = pa.ipc.open_stream(encoded).read_all().to_pandas()
    pd.testing.assert_frame_equal(restored, frame)
