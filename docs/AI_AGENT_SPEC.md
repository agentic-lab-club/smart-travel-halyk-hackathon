# AI Agent Spec

## Role

`AI_Agent` is a stateless planning service for the prototype.

It is responsible for:

- conversational intake support
- normalized field extraction
- trip reasoning
- vibe detection
- visa/weather/review reasoning blocks

It is not responsible for:

- storing trip state
- storing chat state
- calculating final budget totals
- provider integrations
- returning full dashboard aggregate models

## Input Contract

AI_Agent receives:

- `trip_id`
- `action`
- `user_prompt`
- `current_trip`
- `chat_history`

## Output Contract

AI_Agent returns structured JSON:

- `missing_fields`
- `normalized_fields`
- `vibe_labels`
- `visa_insights`
- `weather_insights`
- `review_summaries`
- `assistant_summary`

## Supported Actions

- `collect_fields`
- `generate_plan`
- `regenerate_plan`

## Prompting Model

The prototype assumes one universal system behavior:

- collect or normalize trip intent
- produce structured output
- avoid free-form only answers
- keep output stable for backend consumption

## Backend Integration Pattern

1. App sends user chat to backend
2. Backend forwards context to AI_Agent
3. AI_Agent returns structured fields and reasoning
4. Backend enriches and stores the result

## Mock Countries

The current prototype is centered around:

- Kazakhstan
- Turkey
- UAE
- Japan
