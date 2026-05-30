-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS agent_chat_sessions (
    session_id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_chat_messages (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL
        REFERENCES agent_chat_sessions(session_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL,
    role VARCHAR(32) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    input_text TEXT,
    answer TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_chat_messages_session_user_created
    ON agent_chat_messages(session_id, user_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_agent_chat_messages_assistant_memory
    ON agent_chat_messages(user_id, session_id, role, id DESC);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS agent_chat_messages;
DROP TABLE IF EXISTS agent_chat_sessions;
-- +goose StatementEnd
