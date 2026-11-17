import time
import streamlit as st

def get_success(msg: str, icon: str = ":material/check_circle:"):
    """
    Displays a reusable success toast in Streamlit.

    Args:
        msg (str): The message to display in the toast.
        icon (str): The icon to display alongside the message (Streamlit format).
                    Default is ":material/check_circle:".
    """
    st.success(msg, icon=icon)
    time.sleep(1)