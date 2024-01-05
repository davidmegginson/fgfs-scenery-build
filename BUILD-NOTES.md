FlightGear scenery build notes
==============================

## General issues

### Elevations:

- build overlapping areas in a temp directory, then move target bucket
  into working directory to avoid gullies (Makefile handles this now)

- must build all elevations for a 10x10 bucket at once with gdalchop
  (with overlap)
  
- elevations don't build properly near 180W -- need to do by hand
  somehow -- bug in gdalchop

### OSM:

- leisure=nature-reserve may be a marine area (like the Galapagos), so
  don't use for scenery building


## Specific 10x10 buckets

### w080n40:

- after building bucket, rebuild w74n40 (Manhattan) with SRTM-3,
  because FABDEM fails to filter out the skyscrapers; rebuild tiles
  1745064, 1745072 using SRTM-3

- note also some missing textures in Queens west of KLGA

### w120n10:

- missing texture near MM81

