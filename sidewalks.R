library("ggmap")
library("maptools")
library("rgdal")

# Plot all sidewalks inside a neighbourhood, with different colours for coverage
plot.colours.inside.nh <- function(area.code, map)
{
  nh <- areas[areas@data$AREA_S_CD==area.code, ]
  nh.pts <- fortify(nh)
  cat(paste0("Area is ", nh$AREA_NAME, "\n"))

  inside <- !is.na(over(sw.lat.long, as(nh, "SpatialPolygons")))
  sub <- subset(sw.lat.long, inside)

  sub@data$id <- rownames(sub@data)
  sub.pts <- fortify(sub)
  sub.pts <- merge(sub.pts, sub@data, by="id")

  # now split by SDWLK_Code (13 levels in total, but 8&9 are unused)
  # bad: no sidewalk, ok: one side only, good: both sides/path/walkway
  sdwlk <- c("ok", "ok", "bad", "ok", "ok", "other", "good", NA, NA, "other", "good", "good", "other")

  coverage <- sdwlk[sub.pts$SDWLK_Code]
  sub.pts <- cbind(sub.pts, coverage)

  map +geom_polygon(aes(x=long, y=lat, group=group, alpha=0.25), data=nh.pts, fill='white', show.legend=F) +geom_polygon(aes(x=long, y=lat, group=group), data=nh.pts, color='black', fill=NA, show.legend=F) +geom_path(aes(x=long, y=lat, group=group, color=coverage), data=sub.pts, show.legend=F) +scale_colour_manual(values=c("good"="#00CC33", "ok"="goldenrod", "bad"="red", "other"="blue"))
}


# Read in the Toronto neighbourhoods first
setwd("~/Projects/open-toronto/raw data/neighbourhoods_planning_areas_wgs84")
areas <- readShapeSpatial("neighbourhoods2", CRS("+proj=longlat +datum=WGS84"))

# Now the sidewalks
# At the moment the projection is mislabelled, so set this explicit string
# Once this is corrected, update the proj4string parameter
setwd("~/Projects/open-toronto/raw data/sidewalk_inventory_wgs84")
projection <- "+proj=tmerc +lat_0=0 +lon_0=-79.5 +k=0.9999 +x_0=304800 +y_0=0 +ellps=clrk66 +units=m +no_defs"
sidewalks <- readShapeSpatial("Sidewalk_Inventory_wgs84", proj4string=CRS(projection))
sw.lat.long <- spTransform(sidewalks, CRS("+proj=longlat +datum=WGS84")) # transform into long/lat format to match the neighbourhoods

# Get some maps at different zoom levels
toronto <- qmap("Toronto, Ontario", zoom=10)
toronto2 <- qmap("Toronto, Ontario", zoom=12)
toronto3 <- qmap("Toronto, Ontario", zoom=14)

# Examples of usage. Paste these one at a time into the R console
plot.colours.inside.nh("076", toronto3) # Bay St Corridor
plot.colours.inside.nh("077", toronto2) # Waterfront and The Island
plot.colours.inside.nh("028", toronto)  # Rustic
plot.colours.inside.nh("029", toronto2) # Maple Leaf

