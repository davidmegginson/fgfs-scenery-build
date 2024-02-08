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
  because FABDEM fails to filter out the skyscrapers; in
  w080n40/w074n40 rebuild tiles 1745072 and 1728680

- note also some missing textures in Queens west of KLGA (not yet
  resolved) and at the heliport south of the UN

### w120n10:

- missing texture near MM81

