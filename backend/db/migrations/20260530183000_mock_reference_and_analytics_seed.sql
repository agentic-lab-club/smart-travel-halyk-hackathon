-- +goose Up
-- +goose StatementBegin
-- Analytics DB initialization script
-- Raw transactions tables

CREATE TABLE IF NOT EXISTS kino_ticket_transactions (
    transaction_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,

    purchase_datetime TIMESTAMP NOT NULL,
    event_datetime TIMESTAMP,

    event_id BIGINT,
    event_name VARCHAR(255),

    class_code VARCHAR(50),        -- movie, concert, theatre, tour, sport, family, entertainment
    subclass_code VARCHAR(100),    -- action_movie, electric_bike_tour, rock_concert, kids_show

    genre_code VARCHAR(100),       -- action, comedy, anime, drama; null для не-кино
    city VARCHAR(100),
    venue_name VARCHAR(255),

    tickets_count INT,
    ticket_price NUMERIC(12, 2),
    total_amount NUMERIC(12, 2),

    payment_method VARCHAR(50),    -- halyk_card, bonus, apple_pay, etc.
    bonus_used NUMERIC(12, 2),
    cashback_amount NUMERIC(12, 2),

    source_platform VARCHAR(50),   -- kino_kz_app, kino_kz_web, halyk_app
    status VARCHAR(50),            -- paid, cancelled, refunded

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS account_transactions (
    transaction_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,

    account_id BIGINT NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    -- card, deposit, savings, current_account

    transaction_datetime TIMESTAMP NOT NULL,

    transaction_type VARCHAR(50) NOT NULL,
    -- top_up, withdrawal, transfer_in, transfer_out, deposit_open,
    -- deposit_top_up, deposit_withdrawal, interest_accrual,
    -- card_payment, cashback, fee

    direction VARCHAR(10) NOT NULL,
    -- income, expense

    amount NUMERIC(14, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'KZT',

    balance_before NUMERIC(14, 2),
    balance_after NUMERIC(14, 2),

    counterparty_name VARCHAR(255),
    counterparty_account VARCHAR(100),

    category_code VARCHAR(100),
    category_name VARCHAR(150),

    channel VARCHAR(50),
    -- mobile_app, atm, bank_branch, pos_terminal, online_payment

    description TEXT,

    status VARCHAR(50),
    -- success, pending, failed, reversed

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_kino_tx_user ON kino_ticket_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_kino_tx_purchase_datetime ON kino_ticket_transactions(purchase_datetime);
CREATE INDEX IF NOT EXISTS idx_kino_tx_event_datetime ON kino_ticket_transactions(event_datetime);
CREATE INDEX IF NOT EXISTS idx_kino_tx_class ON kino_ticket_transactions(class_code);
CREATE INDEX IF NOT EXISTS idx_kino_tx_genre ON kino_ticket_transactions(genre_code);
CREATE INDEX IF NOT EXISTS idx_kino_tx_city ON kino_ticket_transactions(city);
CREATE INDEX IF NOT EXISTS idx_kino_tx_status ON kino_ticket_transactions(status);

CREATE INDEX IF NOT EXISTS idx_acc_tx_user ON account_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_acc_tx_account ON account_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_acc_tx_datetime ON account_transactions(transaction_datetime);
CREATE INDEX IF NOT EXISTS idx_acc_tx_type ON account_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_acc_tx_direction ON account_transactions(direction);
CREATE INDEX IF NOT EXISTS idx_acc_tx_category ON account_transactions(category_code);
CREATE INDEX IF NOT EXISTS idx_acc_tx_status ON account_transactions(status);

-- Travel reference data for trip recommendations
CREATE TABLE IF NOT EXISTS travel_countries (
    country_code CHAR(2) PRIMARY KEY,
    name_ru VARCHAR(100) NOT NULL UNIQUE,
    name_en VARCHAR(100) NOT NULL UNIQUE,
    currency_code CHAR(3) NOT NULL,
    timezone_hint VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS travel_cities (
    city_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL REFERENCES travel_countries(country_code) ON DELETE CASCADE,
    name_ru VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    region VARCHAR(150),
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (country_code, name_en)
);

CREATE TABLE IF NOT EXISTS travel_attractions (
    attraction_id SERIAL PRIMARY KEY,
    city_id INT NOT NULL REFERENCES travel_cities(city_id) ON DELETE CASCADE,
    name_ru VARCHAR(180) NOT NULL,
    name_en VARCHAR(180) NOT NULL,
    category VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    recommended_duration_minutes INT CHECK (recommended_duration_minutes IS NULL OR recommended_duration_minutes >= 0),
    price_level VARCHAR(20) NOT NULL DEFAULT 'varies'
        CHECK (price_level IN ('free', 'budget', 'moderate', 'premium', 'varies')),
    is_family_friendly BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (city_id, name_en)
);

CREATE TABLE IF NOT EXISTS popular_restaurants (
    restaurant_id SERIAL PRIMARY KEY,
    city_id INT NOT NULL REFERENCES travel_cities(city_id) ON DELETE CASCADE,
    name VARCHAR(180) NOT NULL,
    cuisine VARCHAR(120) NOT NULL,
    price_level VARCHAR(20) NOT NULL DEFAULT 'moderate'
        CHECK (price_level IN ('budget', 'moderate', 'premium', 'varies')),
    description TEXT NOT NULL,
    area VARCHAR(150),
    reservation_recommended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (city_id, name)
);

CREATE TABLE IF NOT EXISTS seasonal_events (
    seasonal_event_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL REFERENCES travel_countries(country_code) ON DELETE CASCADE,
    city_id INT REFERENCES travel_cities(city_id) ON DELETE CASCADE,
    scope_type VARCHAR(20) NOT NULL CHECK (scope_type IN ('country', 'city')),
    scope_key VARCHAR(120) NOT NULL,
    name_ru VARCHAR(180) NOT NULL,
    name_en VARCHAR(180) NOT NULL,
    category VARCHAR(80) NOT NULL,
    start_month SMALLINT NOT NULL CHECK (start_month BETWEEN 1 AND 12),
    start_day SMALLINT NOT NULL CHECK (start_day BETWEEN 1 AND 31),
    end_month SMALLINT CHECK (end_month BETWEEN 1 AND 12),
    end_day SMALLINT CHECK (end_day BETWEEN 1 AND 31),
    description TEXT NOT NULL,
    travel_tip TEXT,
    is_annual BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        (scope_type = 'country' AND city_id IS NULL)
        OR (scope_type = 'city' AND city_id IS NOT NULL)
    ),
    CHECK (
        (end_month IS NULL AND end_day IS NULL)
        OR (end_month IS NOT NULL AND end_day IS NOT NULL)
    ),
    UNIQUE (country_code, scope_key, name_en)
);

CREATE INDEX IF NOT EXISTS idx_travel_cities_country ON travel_cities(country_code);
CREATE INDEX IF NOT EXISTS idx_travel_attractions_city ON travel_attractions(city_id);
CREATE INDEX IF NOT EXISTS idx_popular_restaurants_city ON popular_restaurants(city_id);
CREATE INDEX IF NOT EXISTS idx_seasonal_events_country ON seasonal_events(country_code);
CREATE INDEX IF NOT EXISTS idx_seasonal_events_city ON seasonal_events(city_id);
CREATE INDEX IF NOT EXISTS idx_seasonal_events_period ON seasonal_events(start_month, start_day, end_month, end_day);

INSERT INTO travel_countries (country_code, name_ru, name_en, currency_code, timezone_hint)
VALUES
    ('JP', 'Япония', 'Japan', 'JPY', 'Asia/Tokyo'),
    ('DE', 'Германия', 'Germany', 'EUR', 'Europe/Berlin'),
    ('KZ', 'Казахстан', 'Kazakhstan', 'KZT', 'Asia/Almaty')
ON CONFLICT (country_code) DO UPDATE SET
    name_ru = EXCLUDED.name_ru,
    name_en = EXCLUDED.name_en,
    currency_code = EXCLUDED.currency_code,
    timezone_hint = EXCLUDED.timezone_hint;

INSERT INTO travel_cities (country_code, name_ru, name_en, region, latitude, longitude, description)
VALUES
    ('JP', 'Токио', 'Tokyo', 'Kanto', 35.676400, 139.650000, 'Столица Японии с кварталами небоскребов, храмами, рынками и современной гастрономией.'),
    ('JP', 'Киото', 'Kyoto', 'Kansai', 35.011600, 135.768100, 'Историческая столица с храмами, садами, традиционными кварталами и сезонной природой.'),
    ('JP', 'Осака', 'Osaka', 'Kansai', 34.693700, 135.502300, 'Город еды, ночных улиц, замка Осаки и удобная база для поездок по региону Kansai.'),
    ('JP', 'Нара', 'Nara', 'Kansai', 34.685100, 135.804800, 'Древняя столица с храмами, парками и знаменитыми оленями у святынь.'),
    ('JP', 'Саппоро', 'Sapporo', 'Hokkaido', 43.061800, 141.354500, 'Крупнейший город Хоккайдо, известный снежными фестивалями, парками и кухней региона.'),
    ('JP', 'Хиросима', 'Hiroshima', 'Chugoku', 34.385300, 132.455300, 'Город памяти, островных маршрутов и региональной версии окономияки.'),
    ('DE', 'Берлин', 'Berlin', 'Berlin', 52.520000, 13.405000, 'Столица Германии с музеями, современной культурой, историческими кварталами и ночной жизнью.'),
    ('DE', 'Мюнхен', 'Munich', 'Bavaria', 48.135100, 11.582000, 'Баварская столица с дворцами, пивными традициями, музеями и близостью к Альпам.'),
    ('DE', 'Гамбург', 'Hamburg', 'Hamburg', 53.551100, 9.993700, 'Портовый город с каналами, Speicherstadt, музыкальными площадками и морской кухней.'),
    ('DE', 'Кельн', 'Cologne', 'North Rhine-Westphalia', 50.937500, 6.960300, 'Рейнский город с собором, карнавалом, музеями и пивными Brauhaus.'),
    ('DE', 'Франкфурт', 'Frankfurt', 'Hesse', 50.110900, 8.682100, 'Финансовый центр с историческим центром, музеями на набережной и яблочным вином.'),
    ('DE', 'Дрезден', 'Dresden', 'Saxony', 51.050400, 13.737300, 'Город барочной архитектуры, музеев, оперы и рождественских традиций Саксонии.'),
    ('KZ', 'Алматы', 'Almaty', 'Almaty', 43.238900, 76.889700, 'Крупнейший город Казахстана у гор Заилийского Алатау, с парками, гастрономией и горными маршрутами.'),
    ('KZ', 'Астана', 'Astana', 'Akmola', 51.169400, 71.449100, 'Столица Казахстана с современной архитектурой, музеями и прогулками вдоль Есиля.'),
    ('KZ', 'Шымкент', 'Shymkent', 'Shymkent', 42.341700, 69.590100, 'Южный город с теплым климатом, рынками, парками и близостью к природным маршрутам.'),
    ('KZ', 'Туркестан', 'Turkistan', 'Turkistan Region', 43.297300, 68.251800, 'Духовный и исторический центр с мавзолеем Ходжи Ахмеда Ясави и новым туристическим кварталом.'),
    ('KZ', 'Актау', 'Aktau', 'Mangystau', 43.658800, 51.197500, 'Город на Каспийском море и база для поездок по природным ландшафтам Мангистау.'),
    ('KZ', 'Караганда', 'Karaganda', 'Karaganda Region', 49.804700, 73.109400, 'Крупный город Центрального Казахстана с музеями, парками и маршрутами к историческим местам региона.')
ON CONFLICT (country_code, name_en) DO UPDATE SET
    name_ru = EXCLUDED.name_ru,
    region = EXCLUDED.region,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    description = EXCLUDED.description;

INSERT INTO travel_attractions (
    city_id, name_ru, name_en, category, description, recommended_duration_minutes, price_level, is_family_friendly
)
SELECT c.city_id, v.name_ru, v.name_en, v.category, v.description, v.recommended_duration_minutes, v.price_level, v.is_family_friendly
FROM (
    VALUES
        ('JP', 'Tokyo', 'Сэнсо-дзи', 'Senso-ji Temple', 'temple', 'Старейший буддийский храм Токио в районе Асакуса, удобный для первой прогулки по традиционному городу.', 90, 'free', TRUE),
        ('JP', 'Tokyo', 'Tokyo Skytree', 'Tokyo Skytree', 'viewpoint', 'Высокая телебашня со смотровыми площадками и торговым комплексом у реки Сумида.', 120, 'premium', TRUE),
        ('JP', 'Tokyo', 'Перекресток Сибуя', 'Shibuya Crossing', 'urban', 'Один из самых узнаваемых городских перекрестков мира, особенно эффектен вечером.', 45, 'free', TRUE),
        ('JP', 'Kyoto', 'Фусими Инари-тайся', 'Fushimi Inari Taisha', 'shrine', 'Синтоистское святилище с тысячами красных ворот тории на лесной горе.', 150, 'free', TRUE),
        ('JP', 'Kyoto', 'Киёмидзу-дэра', 'Kiyomizu-dera', 'temple', 'Храмовый комплекс на холме с деревянной террасой и видами на Киото.', 120, 'budget', TRUE),
        ('JP', 'Kyoto', 'Бамбуковая роща Арасияма', 'Arashiyama Bamboo Grove', 'nature', 'Популярная прогулочная зона с бамбуковой аллеей, храмами и рекой Katsura рядом.', 90, 'free', TRUE),
        ('JP', 'Osaka', 'Замок Осаки', 'Osaka Castle', 'castle', 'Исторический символ города с парком, музеем и обзорными точками.', 120, 'budget', TRUE),
        ('JP', 'Osaka', 'Дотонбори', 'Dotonbori', 'food district', 'Неоновый район у канала с уличной едой, вывесками и вечерней атмосферой.', 120, 'varies', TRUE),
        ('JP', 'Osaka', 'Universal Studios Japan', 'Universal Studios Japan', 'theme park', 'Большой тематический парк, подходящий для семей и фанатов аттракционов.', 420, 'premium', TRUE),
        ('JP', 'Nara', 'Тодай-дзи', 'Todai-ji Temple', 'temple', 'Большой храм с залом Daibutsuden и одной из самых известных статуй Будды в Японии.', 120, 'budget', TRUE),
        ('JP', 'Nara', 'Парк Нара', 'Nara Park', 'park', 'Парк с ручными оленями, соединяющий главные храмы и музеи города.', 120, 'free', TRUE),
        ('JP', 'Nara', 'Касуга-тайся', 'Kasuga Taisha', 'shrine', 'Святилище с каменными и бронзовыми фонарями в лесной зоне.', 90, 'budget', TRUE),
        ('JP', 'Sapporo', 'Парк Одори', 'Odori Park', 'park', 'Центральная зеленая ось Саппоро и площадка для фестивалей, включая снежный фестиваль.', 60, 'free', TRUE),
        ('JP', 'Sapporo', 'Музей пива Саппоро', 'Sapporo Beer Museum', 'museum', 'Музей о пивной истории Хоккайдо рядом с ресторанами в бывшем промышленном комплексе.', 90, 'budget', TRUE),
        ('JP', 'Sapporo', 'Гора Мойва', 'Mount Moiwa', 'viewpoint', 'Смотровая гора с канатной дорогой и панорамой ночного Саппоро.', 150, 'moderate', TRUE),
        ('JP', 'Hiroshima', 'Парк мира в Хиросиме', 'Hiroshima Peace Memorial Park', 'memorial', 'Главное место памяти с музеем, мемориалами и видом на купол Genbaku Dome.', 150, 'budget', TRUE),
        ('JP', 'Hiroshima', 'Замок Хиросимы', 'Hiroshima Castle', 'castle', 'Реконструированный замок с экспозицией об истории города и самурайской культуре.', 90, 'budget', TRUE),
        ('JP', 'Hiroshima', 'Миядзима и Itsukushima Shrine', 'Miyajima and Itsukushima Shrine', 'day trip', 'Островной маршрут к знаменитым воротам тории на воде, удобно как поездка из Хиросимы.', 300, 'moderate', TRUE),
        ('DE', 'Berlin', 'Бранденбургские ворота', 'Brandenburg Gate', 'landmark', 'Главный символ Берлина рядом с Unter den Linden и правительственным кварталом.', 45, 'free', TRUE),
        ('DE', 'Berlin', 'Музейный остров', 'Museum Island', 'museum district', 'Комплекс музеев UNESCO на острове Spreeinsel, лучше планировать заранее.', 240, 'moderate', TRUE),
        ('DE', 'Berlin', 'East Side Gallery', 'East Side Gallery', 'street art', 'Сохранившийся участок Берлинской стены с муралами и прогулкой вдоль Шпрее.', 75, 'free', TRUE),
        ('DE', 'Munich', 'Мариенплац', 'Marienplatz', 'square', 'Историческая площадь в центре Мюнхена с Новой ратушей и удобным стартом прогулки.', 60, 'free', TRUE),
        ('DE', 'Munich', 'Дворец Нимфенбург', 'Nymphenburg Palace', 'palace', 'Большой дворцовый комплекс с парком, павильонами и музейными залами.', 180, 'moderate', TRUE),
        ('DE', 'Munich', 'Английский сад', 'English Garden', 'park', 'Один из крупнейших городских парков Европы с прогулками, Biergarten и серфингом на волне Eisbach.', 120, 'free', TRUE),
        ('DE', 'Hamburg', 'Miniatur Wunderland', 'Miniatur Wunderland', 'museum', 'Популярный музей миниатюрных железных дорог и городских сцен в Speicherstadt.', 180, 'moderate', TRUE),
        ('DE', 'Hamburg', 'Speicherstadt', 'Speicherstadt', 'historic district', 'Кирпичный складской район UNESCO с каналами, мостами и музеями.', 120, 'free', TRUE),
        ('DE', 'Hamburg', 'Эльбская филармония', 'Elbphilharmonie', 'architecture', 'Современный концертный зал и смотровая plaza над портом.', 90, 'budget', TRUE),
        ('DE', 'Cologne', 'Кельнский собор', 'Cologne Cathedral', 'cathedral', 'Готический собор UNESCO рядом с вокзалом, главный ориентир города.', 90, 'free', TRUE),
        ('DE', 'Cologne', 'Мост Гогенцоллернов', 'Hohenzollern Bridge', 'bridge', 'Пешеходный железнодорожный мост с видами на Рейн и собор.', 45, 'free', TRUE),
        ('DE', 'Cologne', 'Музей Людвига', 'Museum Ludwig', 'museum', 'Музей современного искусства с сильной коллекцией поп-арта и работ XX века.', 120, 'moderate', TRUE),
        ('DE', 'Frankfurt', 'Рёмерберг', 'Römerberg', 'square', 'Историческая площадь старого города с фахверковыми фасадами и ратушей Römer.', 60, 'free', TRUE),
        ('DE', 'Frankfurt', 'Штедель', 'Städel Museum', 'museum', 'Один из ключевых художественных музеев Германии на музейной набережной.', 150, 'moderate', TRUE),
        ('DE', 'Frankfurt', 'Пальменгартен', 'Palmengarten', 'garden', 'Ботанический сад с оранжереями, сезонными выставками и спокойными прогулками.', 120, 'moderate', TRUE),
        ('DE', 'Dresden', 'Фрауэнкирхе', 'Frauenkirche', 'church', 'Восстановленная барочная церковь на Neumarkt и символ послевоенного восстановления.', 60, 'free', TRUE),
        ('DE', 'Dresden', 'Цвингер', 'Zwinger Palace', 'palace', 'Барочный дворцовый ансамбль с музеями, галереями и внутренними дворами.', 180, 'moderate', TRUE),
        ('DE', 'Dresden', 'Опера Земпера', 'Semperoper', 'opera house', 'Исторический оперный театр на Theaterplatz, интересен и снаружи, и на экскурсии.', 90, 'moderate', TRUE),
        ('KZ', 'Almaty', 'Кок-Тобе', 'Kok Tobe', 'viewpoint', 'Гора и парк над городом с канатной дорогой, видом на Алматы и вечерними прогулками.', 150, 'moderate', TRUE),
        ('KZ', 'Almaty', 'Медеу', 'Medeu', 'sports venue', 'Высокогорный каток и стартовая точка для поездок к Шымбулаку.', 120, 'budget', TRUE),
        ('KZ', 'Almaty', 'Шымбулак', 'Shymbulak', 'mountain resort', 'Горный курорт для лыжного сезона, подъемников, треккинга и панорам.', 240, 'premium', TRUE),
        ('KZ', 'Astana', 'Байтерек', 'Baiterek', 'landmark', 'Монумент и смотровая площадка, один из главных символов столицы.', 90, 'budget', TRUE),
        ('KZ', 'Astana', 'Национальный музей Казахстана', 'National Museum of Kazakhstan', 'museum', 'Крупный музей о культуре, истории и современной государственности Казахстана.', 150, 'moderate', TRUE),
        ('KZ', 'Astana', 'Хан Шатыр', 'Khan Shatyr', 'architecture', 'Тентовый торгово-развлекательный центр с необычной архитектурой.', 120, 'varies', TRUE),
        ('KZ', 'Shymkent', 'Парк Абая', 'Abay Park', 'park', 'Большой городской парк для прогулок, семейного отдыха и мемориальных зон.', 90, 'free', TRUE),
        ('KZ', 'Shymkent', 'Шымкентский зоопарк', 'Shymkent Zoo', 'zoo', 'Популярная семейная локация и один из известных зоопарков страны.', 150, 'budget', TRUE),
        ('KZ', 'Shymkent', 'Старый город Шымкента', 'Old Town Shymkent', 'historic district', 'Археологическая и прогулочная зона, связанная с ранней историей города.', 90, 'budget', TRUE),
        ('KZ', 'Turkistan', 'Мавзолей Ходжи Ахмеда Ясави', 'Mausoleum of Khoja Ahmed Yasawi', 'mausoleum', 'Памятник UNESCO и ключевая святыня Туркестана.', 120, 'budget', TRUE),
        ('KZ', 'Turkistan', 'Караван-Сарай', 'Karavan Saray', 'tourist complex', 'Современный туристический комплекс с прогулочной зоной, шоу и ресторанами.', 150, 'varies', TRUE),
        ('KZ', 'Turkistan', 'Азрет-Султан', 'Azret Sultan Reserve Museum', 'museum reserve', 'Историко-культурный музей-заповедник вокруг главных памятников Туркестана.', 180, 'moderate', TRUE),
        ('KZ', 'Aktau', 'Набережная Актау', 'Aktau Seafront', 'seafront', 'Прогулочная зона у Каспийского моря, особенно приятна на закате.', 90, 'free', TRUE),
        ('KZ', 'Aktau', 'Бозжыра', 'Bozzhyra', 'day trip', 'Маршрут к известным меловым ландшафтам Мангистау, лучше ехать с подготовленным транспортом.', 480, 'premium', FALSE),
        ('KZ', 'Aktau', 'Долина шаров', 'Valley of Balls', 'day trip', 'Природная локация с каменными конкрециями в степном ландшафте Мангистау.', 360, 'premium', TRUE),
        ('KZ', 'Karaganda', 'Музей Карлага', 'Karlag Museum', 'museum', 'Исторический музей в Долинке о периоде репрессий и системе лагерей.', 180, 'moderate', TRUE),
        ('KZ', 'Karaganda', 'Центральный парк Караганды', 'Karaganda Central Park', 'park', 'Большой городской парк с озером и сезонными прогулками.', 90, 'free', TRUE),
        ('KZ', 'Karaganda', 'Карагандинский областной музей', 'Karaganda Regional Museum', 'museum', 'Музей об истории, природе и промышленном развитии региона.', 90, 'budget', TRUE)
) AS v(country_code, city_name_en, name_ru, name_en, category, description, recommended_duration_minutes, price_level, is_family_friendly)
JOIN travel_cities c ON c.country_code = v.country_code AND c.name_en = v.city_name_en
ON CONFLICT (city_id, name_en) DO UPDATE SET
    name_ru = EXCLUDED.name_ru,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    recommended_duration_minutes = EXCLUDED.recommended_duration_minutes,
    price_level = EXCLUDED.price_level,
    is_family_friendly = EXCLUDED.is_family_friendly;

INSERT INTO popular_restaurants (
    city_id, name, cuisine, price_level, description, area, reservation_recommended
)
SELECT c.city_id, v.name, v.cuisine, v.price_level, v.description, v.area, v.reservation_recommended
FROM (
    VALUES
        ('JP', 'Tokyo', 'Ichiran Shibuya', 'ramen', 'budget', 'Популярная сеть ramen-баров с индивидуальными кабинками и понятным форматом для туристов.', 'Shibuya', FALSE),
        ('JP', 'Tokyo', 'Gonpachi Nishi-Azabu', 'izakaya', 'moderate', 'Известный ресторан-izakaya с атмосферным интерьером и японскими блюдами для компании.', 'Nishi-Azabu', TRUE),
        ('JP', 'Kyoto', 'Honke Owariya', 'soba', 'moderate', 'Историческое место для soba и простых блюд японской кухни в центре Киото.', 'Nakagyo', TRUE),
        ('JP', 'Kyoto', 'Menbaka Fire Ramen', 'ramen', 'moderate', 'Туристически популярный ramen-ресторан с огненной подачей блюда.', 'Kamigyo', TRUE),
        ('JP', 'Osaka', 'Mizuno', 'okonomiyaki', 'moderate', 'Известное место для okonomiyaki в районе Namba и Dotonbori.', 'Dotonbori', TRUE),
        ('JP', 'Osaka', 'Dotonbori Imai', 'udon', 'moderate', 'Классический ресторан udon и kansai-style блюд рядом с главным прогулочным районом.', 'Dotonbori', TRUE),
        ('JP', 'Nara', 'Kamameshi Shizuka', 'kamameshi', 'moderate', 'Популярный ресторан риса kamameshi рядом с Nara Park.', 'Nara Park area', TRUE),
        ('JP', 'Nara', 'Maguro Koya', 'seafood', 'moderate', 'Небольшое известное место с блюдами из тунца и простой японской кухней.', 'Central Nara', FALSE),
        ('JP', 'Sapporo', 'Sapporo Beer Garden', 'jingisukan', 'moderate', 'Крупный ресторанный комплекс для jingisukan и пива в исторической зоне Sapporo Beer Museum.', 'Higashi Ward', TRUE),
        ('JP', 'Sapporo', 'Soup Curry GARAKU', 'soup curry', 'moderate', 'Популярное место для суп-карри, одного из гастрономических символов Саппоро.', 'Odori area', TRUE),
        ('JP', 'Hiroshima', 'Okonomimura', 'okonomiyaki', 'moderate', 'Многоэтажная зона с ресторанами Hiroshima-style okonomiyaki.', 'Naka Ward', FALSE),
        ('JP', 'Hiroshima', 'Nagataya', 'okonomiyaki', 'moderate', 'Известный ресторан Hiroshima-style okonomiyaki недалеко от Peace Memorial Park.', 'Peace Park area', TRUE),
        ('DE', 'Berlin', 'Curry 36', 'street food', 'budget', 'Популярное место для currywurst, удобное для быстрого перекуса.', 'Kreuzberg', FALSE),
        ('DE', 'Berlin', 'Zur letzten Instanz', 'German', 'moderate', 'Исторический ресторан немецкой кухни в старой части Берлина.', 'Mitte', TRUE),
        ('DE', 'Munich', 'Hofbräuhaus München', 'Bavarian', 'moderate', 'Знаменитая пивная с баварской кухней и туристической атмосферой.', 'Altstadt', TRUE),
        ('DE', 'Munich', 'Augustiner-Keller', 'Bavarian', 'moderate', 'Большой традиционный Biergarten и ресторан с классической мюнхенской кухней.', 'Maxvorstadt', TRUE),
        ('DE', 'Hamburg', 'Fischereihafen Restaurant', 'seafood', 'premium', 'Известный ресторан морской кухни у гавани.', 'Altona', TRUE),
        ('DE', 'Hamburg', 'Old Commercial Room', 'German', 'moderate', 'Классический ресторан северогерманской кухни рядом с Michel.', 'Neustadt', TRUE),
        ('DE', 'Cologne', 'Früh am Dom', 'Brauhaus', 'moderate', 'Центральный Brauhaus рядом с собором, известен Kölsch и рейнскими блюдами.', 'Altstadt', TRUE),
        ('DE', 'Cologne', 'Peters Brauhaus', 'Brauhaus', 'moderate', 'Традиционная пивная кухня в Старом городе Кельна.', 'Altstadt', TRUE),
        ('DE', 'Frankfurt', 'Apfelwein Wagner', 'Hessian', 'moderate', 'Классическое место для яблочного вина и блюд Гессена в Sachsenhausen.', 'Sachsenhausen', TRUE),
        ('DE', 'Frankfurt', 'Atschel', 'Hessian', 'moderate', 'Популярный apple wine tavern с традиционной кухней Франкфурта.', 'Sachsenhausen', TRUE),
        ('DE', 'Dresden', 'Sophienkeller', 'Saxon', 'moderate', 'Атмосферный ресторан саксонской кухни в историческом центре.', 'Altstadt', TRUE),
        ('DE', 'Dresden', 'Pulverturm an der Frauenkirche', 'Saxon', 'moderate', 'Туристически популярный ресторан рядом с Frauenkirche с историческим интерьером.', 'Neumarkt', TRUE),
        ('KZ', 'Almaty', 'Navat Almaty', 'Central Asian', 'moderate', 'Популярный ресторан восточной и центральноазиатской кухни с несколькими точками в городе.', 'Central Almaty', TRUE),
        ('KZ', 'Almaty', 'Auyl', 'Kazakh', 'premium', 'Ресторан казахской кухни с акцентом на национальную подачу и локальные продукты.', 'Medeu area', TRUE),
        ('KZ', 'Astana', 'Qazaq Gourmet', 'Kazakh', 'premium', 'Ресторан современной казахской кухни и локальных гастрономических традиций.', 'Left Bank', TRUE),
        ('KZ', 'Astana', 'Sandyq Astana', 'Kazakh', 'moderate', 'Ресторан-музей с казахской кухней и национальным интерьером.', 'Central Astana', TRUE),
        ('KZ', 'Shymkent', 'Bar Villa', 'European and local', 'moderate', 'Известное городское место для ужина и встреч в Шымкенте.', 'Central Shymkent', TRUE),
        ('KZ', 'Shymkent', 'Kok-Saray', 'Central Asian', 'moderate', 'Ресторан с блюдами центральноазиатской кухни и форматом для семейного ужина.', 'Central Shymkent', TRUE),
        ('KZ', 'Turkistan', 'Karavan Saray Food Hall', 'varied', 'moderate', 'Удобная точка питания внутри туристического комплекса Karavan Saray.', 'Karavan Saray', FALSE),
        ('KZ', 'Turkistan', 'Sultan Saray', 'Central Asian', 'moderate', 'Ресторан с центральноазиатскими блюдами для туристов и групп.', 'Central Turkistan', TRUE),
        ('KZ', 'Aktau', 'Barashka Dine & Drink', 'Central Asian', 'moderate', 'Популярный ресторанный формат для ужина у гостей города.', 'Aktau center', TRUE),
        ('KZ', 'Aktau', 'Beef Eater Aktau', 'steakhouse', 'premium', 'Стейкхаус и ресторан для плотного ужина после маршрутов по Мангистау.', 'Aktau center', TRUE),
        ('KZ', 'Karaganda', 'Line Brew Karaganda', 'steakhouse', 'premium', 'Известный ресторан мясной кухни в Караганде.', 'Central Karaganda', TRUE),
        ('KZ', 'Karaganda', 'Villa Borghese', 'Italian', 'moderate', 'Популярный ресторан итальянской и европейской кухни для ужина.', 'Central Karaganda', TRUE)
) AS v(country_code, city_name_en, name, cuisine, price_level, description, area, reservation_recommended)
JOIN travel_cities c ON c.country_code = v.country_code AND c.name_en = v.city_name_en
ON CONFLICT (city_id, name) DO UPDATE SET
    cuisine = EXCLUDED.cuisine,
    price_level = EXCLUDED.price_level,
    description = EXCLUDED.description,
    area = EXCLUDED.area,
    reservation_recommended = EXCLUDED.reservation_recommended;

INSERT INTO seasonal_events (
    country_code, city_id, scope_type, scope_key, name_ru, name_en, category,
    start_month, start_day, end_month, end_day, description, travel_tip, is_annual
)
SELECT
    v.country_code,
    c.city_id,
    CASE WHEN v.city_name_en IS NULL THEN 'country' ELSE 'city' END,
    LOWER(COALESCE(v.city_name_en, 'country')),
    v.name_ru,
    v.name_en,
    v.category,
    v.start_month,
    v.start_day,
    v.end_month,
    v.end_day,
    v.description,
    v.travel_tip,
    v.is_annual
FROM (
    VALUES
        ('JP', NULL, 'Цветение сакуры', 'Cherry Blossom Season', 'nature', 3, 20, 4, 10, 'Ориентировочный сезон сакуры в центральной Японии, включая Токио, Киото и Осаку.', 'Пик меняется по погоде и региону, перед поездкой лучше проверить прогноз цветения.', TRUE),
        ('JP', NULL, 'Золотая неделя', 'Golden Week', 'holiday', 4, 29, 5, 5, 'Серия национальных праздников и один из самых загруженных периодов внутренних путешествий.', 'Бронировать отели и поезда стоит заранее, популярные места бывают переполнены.', TRUE),
        ('JP', 'Kyoto', 'Гион-мацури', 'Gion Matsuri', 'festival', 7, 1, 7, 31, 'Крупный летний фестиваль Киото с процессиями и традиционными повозками.', 'Главные дни особенно загружены, жилье в центре лучше бронировать заранее.', TRUE),
        ('JP', 'Sapporo', 'Снежный фестиваль Саппоро', 'Sapporo Snow Festival', 'festival', 2, 1, 2, 12, 'Зимний фестиваль снежных и ледяных скульптур в центре Саппоро.', 'Нужна теплая обувь, а даты каждый год стоит уточнять перед поездкой.', TRUE),
        ('JP', NULL, 'Осенние клены', 'Autumn Foliage', 'nature', 10, 20, 12, 5, 'Сезон красных кленов и осенней листвы, двигается с севера на юг.', 'Для Киото и Нары часто хорош конец ноября, но пик зависит от погоды.', TRUE),
        ('DE', 'Munich', 'Октоберфест', 'Oktoberfest', 'festival', 9, 15, 10, 6, 'Крупнейший мюнхенский Volksfest с пивными шатрами, аттракционами и баварскими традициями.', 'Точные даты меняются по году, столы в популярных шатрах бронируют заранее.', TRUE),
        ('DE', NULL, 'Рождественские рынки', 'Christmas Markets', 'holiday market', 11, 20, 12, 24, 'Сезон Weihnachtsmarkt в городах Германии с ремеслами, едой и Glühwein.', 'Некоторые рынки закрываются 24 декабря или раньше, расписание нужно проверять по городу.', TRUE),
        ('DE', 'Cologne', 'Кельнский карнавал', 'Cologne Carnival', 'festival', 2, 1, 3, 10, 'Карнавальный сезон с парадами, костюмами и главным пиком перед Великим постом.', 'Даты зависят от Пасхи, а в дни парадов город сильно загружен.', TRUE),
        ('DE', 'Berlin', 'Фестиваль света', 'Festival of Lights Berlin', 'festival', 10, 1, 10, 15, 'Осенний световой фестиваль с подсветкой городских достопримечательностей.', 'Маршрут удобно планировать пешком и на общественном транспорте.', TRUE),
        ('DE', NULL, 'День германского единства', 'German Unity Day', 'holiday', 10, 3, NULL, NULL, 'Национальный праздник Германии 3 октября.', 'Музеи и магазины могут работать по праздничному расписанию.', TRUE),
        ('KZ', NULL, 'Наурыз', 'Nauryz', 'holiday', 3, 21, 3, 23, 'Весенний праздник обновления, один из главных праздников Казахстана.', 'В городах проходят концерты и ярмарки, часть сервисов может работать по праздничному графику.', TRUE),
        ('KZ', 'Astana', 'День столицы', 'Capital City Day', 'holiday', 7, 6, NULL, NULL, 'Праздник столицы с городскими мероприятиями в Астане.', 'Программу мероприятий лучше проверять ближе к дате.', TRUE),
        ('KZ', 'Almaty', 'Сезон яблок и гастрособытий', 'Apple and Food Season', 'food season', 9, 1, 10, 15, 'Осенний период, когда Алматы особенно ассоциируется с яблоками, рынками и гастрономией.', 'Хорошее время для городских прогулок и поездок в горы без летней жары.', TRUE),
        ('KZ', 'Almaty', 'Горнолыжный сезон Шымбулак', 'Shymbulak Ski Season', 'winter sport', 12, 1, 3, 31, 'Ориентировочный сезон катания на Шымбулаке рядом с Алматы.', 'Состояние трасс зависит от снега, перед поездкой нужно проверить работу подъемников.', TRUE),
        ('KZ', 'Aktau', 'Каспийский пляжный сезон', 'Caspian Beach Season', 'beach season', 6, 1, 9, 15, 'Теплый сезон для прогулок и отдыха у Каспийского моря в Актау.', 'Летом важно учитывать жару, ветер и заранее планировать выезды по Мангистау.', TRUE),
        ('KZ', 'Turkistan', 'Комфортный сезон Туркестана', 'Comfort Season in Turkistan', 'weather window', 4, 1, 6, 10, 'Весна и начало лета обычно удобнее для осмотра исторических мест до сильной жары.', 'Для прогулок лучше выбирать утро или вечер, особенно ближе к лету.', TRUE)
) AS v(country_code, city_name_en, name_ru, name_en, category, start_month, start_day, end_month, end_day, description, travel_tip, is_annual)
LEFT JOIN travel_cities c ON c.country_code = v.country_code AND c.name_en = v.city_name_en
ON CONFLICT (country_code, scope_key, name_en) DO UPDATE SET
    city_id = EXCLUDED.city_id,
    scope_type = EXCLUDED.scope_type,
    name_ru = EXCLUDED.name_ru,
    category = EXCLUDED.category,
    start_month = EXCLUDED.start_month,
    start_day = EXCLUDED.start_day,
    end_month = EXCLUDED.end_month,
    end_day = EXCLUDED.end_day,
    description = EXCLUDED.description,
    travel_tip = EXCLUDED.travel_tip,
    is_annual = EXCLUDED.is_annual;


-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS seasonal_events;
DROP TABLE IF EXISTS popular_restaurants;
DROP TABLE IF EXISTS travel_attractions;
DROP TABLE IF EXISTS travel_cities;
DROP TABLE IF EXISTS travel_countries;
DROP TABLE IF EXISTS account_transactions;
DROP TABLE IF EXISTS kino_ticket_transactions;
-- +goose StatementEnd

