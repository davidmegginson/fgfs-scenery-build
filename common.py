def get_bucket (lat, lon):
    lat_dir = 's' if lat < 0 else 'n'
    lon_dir = 'w' if lon < 0 else 'e'
    lat = abs(int(float(lat)/10)*10)
    lon = abs(int(float(lon)/10)*10)
    return "{}{:d}{}{:d}".format(lon_dir, lon, lat_dir, lat)
    
