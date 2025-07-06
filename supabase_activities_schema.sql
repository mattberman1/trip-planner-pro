-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    city_id UUID NOT NULL REFERENCES map_locations(id) ON DELETE CASCADE,
    poi_name TEXT,
    poi_address TEXT,
    poi_latitude DOUBLE PRECISION,
    poi_longitude DOUBLE PRECISION,
    category TEXT NOT NULL CHECK (category IN ('places', 'tours', 'restaurant', 'bar', 'travel', 'hotel')),
    notes TEXT,
    is_added_to_calendar BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_activities_trip_id ON activities(trip_id);
CREATE INDEX IF NOT EXISTS idx_activities_date ON activities(date);
CREATE INDEX IF NOT EXISTS idx_activities_category ON activities(category);

-- Enable Row Level Security (RLS)
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (you can customize this based on your auth needs)
CREATE POLICY "Allow all operations on activities" ON activities
    FOR ALL USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_activities_updated_at 
    BEFORE UPDATE ON activities 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 