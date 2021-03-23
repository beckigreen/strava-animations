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

#Selecting data of interest - Blenheim Tri
my_acts_tri <- my_acts_filt %>% 
  filter(year == 2019 & month == 6 & day == 2)

#Using polyline data to get latitude and longitude, adding variable indicating the time sequence of data points
my_acts_tri <- my_acts_tri %>%
  arrange(start_date) %>%
  filter(!is.na(map.summary_polyline)) %>%
  group_by(activity_no) %>%
  nest() %>%
  mutate(coords = map(data, function(x) get_latlon(x$map.summary_polyline, key=google_key))) %>%
  unnest(., c(data, coords)) %>%
  ungroup() %>%
  mutate(n = as.numeric(seq(1, n())))

#Import & format sport icons for plotting - these icon links can be replaced with any image link you wish
sport <- list(bike = "https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/apple/271/bicycle_1f6b2.png",
     swim = "https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/apple/271/woman-swimming_1f3ca-200d-2640-fe0f.png",
     run ="https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/apple/271/woman-running_1f3c3-200d-2640-fe0f.png")

for (i in names(sport)){
  image_read(sport[[i]]) %>%
    image_transparent('white') %>%
    image_write(path = paste0(i, "_logo.png"))
}

#Store icons in image column
my_acts_tri <- my_acts_tri %>% 
  mutate(image = case_when(
  type == "Swim" ~ "swim_logo.png",
  type == "Ride" ~ "bike_logo.png",
  type == "Run" | type == "Workout" ~ "run_logo.png"))

#Get map background
bbox <- ggmap::make_bbox(lon, lat, data = my_acts_tri, f = 0.1)
map <- get_map(location = bbox, source = 'google', maptype = 'terrain')

#Labels
plot_titles <- list(
  title = ("<strong>Triathlon animation using <span style=\'color:#ffffff'\">Strava</span> data</strong>"),
  subtitle = ("<span style=\'color:#454545'\">**Blenheim Palace, Oxfordshire**</span>"),
  caption = ("<span style=\'color:#454545'\">|| **Visualisation:** @becki_e_green</span>"))

#Plot
p = ggmap(map) +
  geom_path(data = my_acts_tri, aes(x = lon, y = lat, col = activity_no), size=0.7, alpha = 0.6) +
  geom_image(data = my_acts_tri, aes(image = image, group = activity_no), size = 0.05) + 
  transition_reveal(n, keep_last = F) +   
  scale_color_brewer(palette = "Set1") + 
  labs(title = plot_titles$title, subtitle = plot_titles$subtitle, caption = plot_titles$caption) +
  theme(plot.title = element_markdown(size=15),  plot.subtitle = element_markdown(size=12), plot.caption = element_markdown(size=10),
        legend.position="none", axis.text=element_blank(), axis.ticks = element_blank(), 
        axis.title = element_blank(), plot.background = element_rect(fill = "darkorange1"))

animate(p, nframes = 200, fps=12, res=150, h=800, w=800, bg = 'transparent')
anim_save("animations/triathlon_anim.gif")

########END########

