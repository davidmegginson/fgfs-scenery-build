FlightGear scenery build notes
==============================

## General issues

### Elevations:

- build overlapping areas in a temp directory, then move target bucket
  into working directory to avoid gullies (Makefile handles this now)

### OSM:

- leisure=nature-reserve may be a marine area (like the Galapagos), so
  don't use for scenery building


## Specific 10x10 buckets

### w080n40:

- after building bucket, rebuild w74n40 (Manhattan) with SRTM-3,
  because FABDEM fails to filter out the skyscrapers; rebuild tile
  1745064 using SRTM-3

- note also some missing textures in Queens west of KLGA

### w120n10:

- blank tile near MM81

