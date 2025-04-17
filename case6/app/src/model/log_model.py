from typing import Optional
from pydantic import Field
from model.common_model import CommonModel

class LogExtraInfo(CommonModel):
    user_id: Optional[str] = Field(default=None)

    def __str__(self):
        json_str = self.model_dump_json(exclude_none=True)
        # もし何もセットされていなければ、json_str = {} となる
        if len(json_str) == 2:
            return ""
        return f" context: {json_str}"


class LogMessage(CommonModel):
    timestamp: str = Field(default="")
    level: str = Field(default="")
    message: str = Field(default="")
    env_context: str = Field(default="")
    file: str = Field(default="")
    line: int = Field(default=None)
    function: str = Field(default="")
    extra_info: LogExtraInfo = LogExtraInfo()
