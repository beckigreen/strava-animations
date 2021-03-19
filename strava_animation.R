########START########

#Extracting and compiling Strava data
library(rStrava) 

#Tidying data
library(dplyr) 
library(tidyr)
library(purrr)

#Visualising data
library(ggplot2)
library(gganimate) 
library(ggmap)
library(ggimage)
library(ggtext)
library(RColorBrewer)
library(magick) 

#Strava API - this needs to be filled in with your unique information
app_name <- 'xxxxx' 
app_client_id  <- 'xxxxx' 
app_secret <- 'xxxxxxxxxx' 
athlete_id <- 'xxxxx'

#Google API -  this needs to be filled in with your unique information
google_key <- 'xxxxxxxxxx' 

#Strava token
stoken <- httr::config(token = strava_oauth(app_name, app_client_id, app_secret, app_scope="activity:read_all", cache=T))
myinfo <- get_athlete(stoken, athlete_id)

#Importing data
my_acts <- get_activity_list(stoken)
my_acts <- compile_activities(my_acts)
glimpse(my_acts)

#Filtering data and converting variables into readable formats
my_acts_filt <- my_acts %>% 
  dplyr::select(c('elapsed_time', 'moving_time', 'distance', 'type', 'map.summary_polyline', 'start_date', 'upload_id')) %>%
  arrange(start_date) %>%
  mutate(activity_no = seq(1, n()),
         elapsed_time = elapsed_time/60/60,
         moving_time = moving_time/60/60,
         start_date = gsub("T.*$", '', start_date) %>%
           as.POSIXct(format = '%Y-%m-%d'),
         month = format(start_date, "%m"),
         day = format(start_date, "%d"),
         year = format(start_date, "%Y")) %>%
  mutate_at(c('elapsed_time', 'moving_time', 'distance', 'month', 'day', 'year'), as.numeric) %>%
  mutate_at(c('activity_no', 'upload_id', 'type'), as.factor)

#Checking
sapply(my_acts_filt, class) 

#Selecting data of interest - Aug-Dec 2020
my_acts_ride <- my_acts_filt %>% 
  filter(type == "Ride") %>% 
  filter(year == 2020 & month >= 8)

#Using polyline data to get latitude and longitude, adding variable indicating the time sequence of data points
my_acts_ride <- my_acts_ride %>%
  arrange(start_date) %>%
  filter(!is.na(map.summary_polyline)) %>%
  group_by(activity_no) %>%
  nest() %>%
  mutate(coords = map(data, function(x) get_latlon(x$map.summary_polyline, key=google_key)),) %>%
  unnest(., c(data, coords)) %>%
  ungroup() %>%
  mutate(n = as.numeric(seq(1, n())))

#Add bike icon for plotting - this icon link can be replaced with any image link you wish
image_link <- "https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/apple/271/bicycle_1f6b2.png"

image_link %>% 
  image_read() %>%
  image_transparent('white') %>%
  image_write(path = "bike_logo.png", format = "png")

image_local <- "bike_logo.png"

my_acts_ride <- my_acts_ride %>% 
  mutate(image= image_local)

#Get map background
bbox <- ggmap::make_bbox(lon, lat, data = my_acts_ride, f = 0.15)
map <- get_map(location = bbox, source = 'google', maptype = 'terrain')

#Colour palette
cols <- length(unique(my_acts_ride$activity_no))
mycolors <- colorRampPalette(brewer.pal(8, "Set1")[c(1:5, 7:8)])(cols) #all colours except yellow

#Labels
plot_titles <- list(
  title = ("<strong>A map of outdoor rides using <span style=\'color:#ffffff'\">Strava</span> data</strong>"),
  subtitle = ("<span style=\'color:#454545'\">**August to December 2020**</span>"),
  caption = ("<span style=\'color:#454545'\">|| **Visualisation:** @becki_e_green</span>"))

#Plot
p = ggmap(map) +
  geom_path(data = my_acts_ride, aes(x = lon, y = lat, col = activity_no), size=0.7) +
  geom_image(data = my_acts_ride, aes(image = image), size = 0.05) + 
  transition_reveal(n) +   
  scale_color_manual(values = sample(mycolors)) + 
  labs(title = plot_titles$title, subtitle = plot_titles$subtitle, caption = plot_titles$caption) +
  theme(plot.title = element_markdown(size=15), plot.subtitle = element_markdown(size=12), plot.caption = element_markdown(size=10),
        legend.position="none", axis.text=element_blank(), axis.ticks = element_blank(), 
        axis.title = element_blank(), plot.background = element_rect(fill = "darkorange1"))

animate(p, nframes = 200, fps=12, res=150, h=1200, w=700)
anim_save("animations/strava_anim.gif")

########END########
