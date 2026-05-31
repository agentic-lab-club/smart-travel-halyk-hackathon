-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS travel_trip_recommendations (
    trip_id TEXT PRIMARY KEY,
    destination_name TEXT NOT NULL,
    destination_title TEXT NOT NULL,
    country_code CHAR(2) NOT NULL,
    city_codes TEXT[] NOT NULL DEFAULT '{}',
    start_date DATE,
    end_date DATE,
    duration_days INT NOT NULL CHECK (duration_days > 0),
    image_url TEXT,
    estimated_total_cost NUMERIC(12, 2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'KZT',
    confidence TEXT NOT NULL DEFAULT 'medium',
    cashback_amount NUMERIC(12, 2),
    cashback_percent NUMERIC(5, 2),
    main_reason TEXT NOT NULL,
    reason_labels TEXT[] NOT NULL DEFAULT '{}',
    recommendation_type TEXT NOT NULL CHECK (
        recommendation_type IN (
            'similar_to_previous',
            'opposite_to_previous',
            'seasonal',
            'event_based',
            'budget_friendly',
            'cashback_boosted',
            'visa_free',
            'weekend_trip'
        )
    ),
    score NUMERIC(5, 4) NOT NULL DEFAULT 0.5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_travel_trip_recommendations_type_score
    ON travel_trip_recommendations(recommendation_type, score DESC);

INSERT INTO travel_trip_recommendations (
    trip_id,
    destination_name,
    destination_title,
    country_code,
    city_codes,
    start_date,
    end_date,
    duration_days,
    image_url,
    estimated_total_cost,
    currency,
    confidence,
    cashback_amount,
    cashback_percent,
    main_reason,
    reason_labels,
    recommendation_type,
    score
)
VALUES
    ('rec-similar-tokyo-001', 'Tokyo, Japan', 'Tokyo family food and culture week', 'JP', ARRAY['TYO'], '2026-07-10', '2026-07-17', 8, 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf', 905000, 'KZT', 'high', 45250, 5.0, 'Close to prior culture and food patterns with a family-safe city route.', ARRAY['Culture', 'Food', 'Family fit', 'Direct path'], 'similar_to_previous', 0.9700),
    ('rec-similar-kyoto-002', 'Kyoto, Japan', 'Kyoto temples and quiet lanes', 'JP', ARRAY['KIX','UKY'], '2026-09-12', '2026-09-18', 7, 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e', 845000, 'KZT', 'medium', 38025, 4.5, 'Matches the user preference for history, walkable days, and calm food districts.', ARRAY['History', 'Quiet', 'Walkable', 'Seasonal color'], 'similar_to_previous', 0.9400),
    ('rec-similar-istanbul-003', 'Istanbul, Turkey', 'Istanbul markets and Bosphorus food route', 'TR', ARRAY['IST'], '2026-06-12', '2026-06-16', 5, 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200', 742000, 'KZT', 'high', 31500, 4.2, 'Visa-free, direct flight from Almaty, strong food and history match.', ARRAY['Visa-free', 'Food match', 'History', 'Cashback boost'], 'similar_to_previous', 0.9200),
    ('rec-similar-tbilisi-004', 'Tbilisi, Georgia', 'Tbilisi old town and wine route', 'GE', ARRAY['TBS'], '2026-06-20', '2026-06-24', 5, 'https://images.unsplash.com/photo-1565008576549-57569a49371d', 586000, 'KZT', 'medium', 18000, 3.0, 'Short flight, familiar cuisine, and easy old town walking days.', ARRAY['Budget friendly', 'Food', 'Mountains', 'Old town'], 'similar_to_previous', 0.8900),
    ('rec-similar-almaty-005', 'Almaty, Kazakhstan', 'Almaty mountain reset weekend', 'KZ', ARRAY['ALA'], '2026-06-27', '2026-06-29', 3, 'https://images.unsplash.com/photo-1596367407372-5af9a8b8d67e', 180000, 'KZT', 'high', 5500, 3.0, 'No visa, no flight stress, and a strong mountain-and-food fit.', ARRAY['No visa', 'Mountains', 'Weekend getaway', 'Food'], 'similar_to_previous', 0.8600),

    ('rec-new-dubai-001', 'Dubai, UAE', 'Dubai beach, shopping and desert contrast', 'AE', ARRAY['DXB'], '2026-07-04', '2026-07-09', 6, 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c', 890000, 'KZT', 'medium', 32000, 3.5, 'A brighter luxury-and-desert style that contrasts with prior city history trips.', ARRAY['Beach', 'Shopping', 'Desert', 'New style'], 'opposite_to_previous', 0.9500),
    ('rec-new-baku-002', 'Baku, Azerbaijan', 'Baku Caspian design and old city break', 'AZ', ARRAY['GYD'], '2026-08-08', '2026-08-13', 6, 'https://images.unsplash.com/photo-1581007341315-6d53c1f9f7fb', 640000, 'KZT', 'medium', 22400, 3.5, 'Mixes seaside walks, modern architecture, and old city streets in a new pattern.', ARRAY['Sea', 'Architecture', 'Old city', 'Direct flight'], 'opposite_to_previous', 0.9100),
    ('rec-new-batumi-003', 'Batumi, Georgia', 'Batumi Black Sea family coast', 'GE', ARRAY['BUS'], '2026-08-15', '2026-08-20', 6, 'https://images.unsplash.com/photo-1565008576549-57569a49371d', 520000, 'KZT', 'medium', 15600, 3.0, 'A sea-first option for a user whose profile is usually city and culture led.', ARRAY['Sea', 'Family', 'Budget friendly', 'Relaxed'], 'opposite_to_previous', 0.8800),
    ('rec-new-doha-004', 'Doha, Qatar', 'Doha museums, souq and warm winter sun', 'QA', ARRAY['DOH'], '2026-11-05', '2026-11-10', 6, 'https://images.unsplash.com/photo-1629126791508-92c68ba0e8d2', 820000, 'KZT', 'medium', 28700, 3.5, 'A polished Gulf city route with a different climate, pace, and museum style.', ARRAY['Museums', 'Warm weather', 'Souq', 'New style'], 'opposite_to_previous', 0.8500),
    ('rec-new-seoul-005', 'Seoul, South Korea', 'Seoul pop culture and palaces route', 'KR', ARRAY['SEL'], '2026-10-03', '2026-10-09', 7, 'https://images.unsplash.com/photo-1538485399081-7191377e8241', 965000, 'KZT', 'medium', 38600, 4.0, 'Adds a trendier city-energy route with shopping, media culture, and palace walks.', ARRAY['Shopping', 'Culture', 'Food', 'City energy'], 'opposite_to_previous', 0.8200),

    ('rec-seasonal-sapporo-001', 'Sapporo, Japan', 'Sapporo snow festival and winter food', 'JP', ARRAY['CTS'], '2026-02-05', '2026-02-11', 7, 'https://images.unsplash.com/photo-1516563670759-299070f0dc54', 930000, 'KZT', 'medium', 37200, 4.0, 'Timed around winter festival energy, snow scenery, and regional comfort food.', ARRAY['Seasonal', 'Winter', 'Food', 'Festival'], 'seasonal', 0.9600),
    ('rec-seasonal-munich-002', 'Munich, Germany', 'Munich autumn parks and museum week', 'DE', ARRAY['MUC'], '2026-09-19', '2026-09-25', 7, 'https://images.unsplash.com/photo-1595867818082-083862f3d630', 870000, 'KZT', 'medium', 34800, 4.0, 'Autumn timing fits parks, museums, and calmer family city days.', ARRAY['Seasonal', 'Autumn', 'Museums', 'Parks'], 'seasonal', 0.9200),
    ('rec-seasonal-astana-003', 'Astana, Kazakhstan', 'Astana summer architecture weekend', 'KZ', ARRAY['NQZ'], '2026-07-18', '2026-07-21', 4, 'https://images.unsplash.com/photo-1577086664693-894d8405334a', 240000, 'KZT', 'high', 7200, 3.0, 'Best in warmer months for river walks, modern architecture, and short domestic travel.', ARRAY['Seasonal', 'Weekend', 'No visa', 'Architecture'], 'seasonal', 0.8800),
    ('rec-event-berlin-004', 'Berlin, Germany', 'Berlin summer museums and open-air events', 'DE', ARRAY['BER'], '2026-08-01', '2026-08-07', 7, 'https://images.unsplash.com/photo-1560969184-10fe8719e047', 835000, 'KZT', 'medium', 33400, 4.0, 'Event-friendly summer timing with museums, public squares, and evening culture.', ARRAY['Events', 'Museums', 'Summer', 'Culture'], 'event_based', 0.8500),
    ('rec-event-almaty-005', 'Almaty, Kazakhstan', 'Almaty concerts and mountain day plan', 'KZ', ARRAY['ALA'], '2026-08-22', '2026-08-25', 4, 'https://images.unsplash.com/photo-1596367407372-5af9a8b8d67e', 220000, 'KZT', 'high', 8800, 4.0, 'Combines likely city events with an easy mountain day for a timely local plan.', ARRAY['Events', 'Mountains', 'No visa', 'Weekend'], 'event_based', 0.8200)
ON CONFLICT (trip_id) DO UPDATE SET
    destination_name = EXCLUDED.destination_name,
    destination_title = EXCLUDED.destination_title,
    country_code = EXCLUDED.country_code,
    city_codes = EXCLUDED.city_codes,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    duration_days = EXCLUDED.duration_days,
    image_url = EXCLUDED.image_url,
    estimated_total_cost = EXCLUDED.estimated_total_cost,
    currency = EXCLUDED.currency,
    confidence = EXCLUDED.confidence,
    cashback_amount = EXCLUDED.cashback_amount,
    cashback_percent = EXCLUDED.cashback_percent,
    main_reason = EXCLUDED.main_reason,
    reason_labels = EXCLUDED.reason_labels,
    recommendation_type = EXCLUDED.recommendation_type,
    score = EXCLUDED.score,
    updated_at = NOW();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS travel_trip_recommendations;
-- +goose StatementEnd
