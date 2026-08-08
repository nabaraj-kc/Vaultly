from pydantic import BaseModel, Field
from typing import Optional, List

class TextProcessRequest(BaseModel):
    text: str = Field(..., description="The raw document text extracted by client/fallback parser.")
    action: str = Field(..., description="Action to perform: 'summarize', 'proposal', or 'insights'")
    user_tier: str = Field("free", description="User subscription tier: 'free' or 'pro'")
    user_id: Optional[str] = Field("default_user", description="Identifier to track daily usage")

class AIOutputResponse(BaseModel):
    status: str = Field(..., description="Status of the operation, typically 'success' or 'error'")
    result: str = Field(..., description="AI generated output in Markdown or formatted text")
    remaining_credits: int = Field(..., description="Number of remaining free credits for the day")
    error_message: Optional[str] = Field(None, description="Detailed error description if any")

class FallbackExtractResponse(BaseModel):
    status: str = Field(..., description="'success' or 'error'")
    extracted_text: str = Field(..., description="Extracted text parsed from the binary file")
    error_message: Optional[str] = Field(None, description="Detailed error description if any")
