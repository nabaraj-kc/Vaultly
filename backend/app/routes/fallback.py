from fastapi import APIRouter, UploadFile, File, HTTPException, status
from app.schemas import FallbackExtractResponse
from app.services.extractor import ExtractorService

router = APIRouter(prefix="/api/files", tags=["Fallback Parsing"])

@router.post("/extract-fallback", response_model=FallbackExtractResponse)
async def extract_fallback(file: UploadFile = File(...)):
    """Receives binary files, extracts text content, and returns raw text to the client."""
    # Safety Check: Limit input file extension list
    import os
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in [".txt", ".pdf", ".docx", ".doc"]:
         raise HTTPException(
             status_code=status.HTTP_400_BAD_REQUEST,
             detail=f"Unsupported file format '{ext}'. Only PDF, DOCX, and TXT are supported by fallback parser."
         )

    try:
        # Read file contents securely in memory
        content_bytes = await file.read()
        
        extracted_text = ExtractorService.extract_text_from_bytes(content_bytes, file.filename)
        
        return FallbackExtractResponse(
            status="success",
            extracted_text=extracted_text
        )
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(val_err)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Fallback file parsing failed: {str(e)}"
        )
    finally:
        await file.close()
