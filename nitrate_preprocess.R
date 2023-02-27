# Nitrogen monitor data for Tweed

# Original CSV files in dreadful format with double header lines
rawd <- read.csv("data/lois/data/lois_majorion-nutrient.csv", skip = 1)
tmp <- dplyr::filter(rawd, substring(SITE_NAME, 1, 5) == "Tweed")
tweed_n <- tmp[, c(1:4, 20)]
colnames(tweed_n) <- c("FID", "ID", "site_name", "date", "nitrate")
tweed_n$date <- as.POSIXct(tweed_n$date, format = "%d/%m/%Y %H:%M")

rawd <- read.csv("data/lois/supporting-documents/LOISCP_Sites.csv", skip = 1)
tmp <- dplyr::filter(rawd, substring(Site.Name, 1, 5) == "Tweed")
tweed_coords <- tmp[, 1:5]
colnames(tweed_coords) <- c("FID", "ID", "site_name", "easting", "northing")

tweed_n <- dplyr::full_join(tweed_n, tweed_coords)
