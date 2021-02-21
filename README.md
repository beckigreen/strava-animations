# Creating Strava animations using rStrava and gganimate 🏊 🚲 🏃

If you want to explore more of the functionalities within the rStrava package, I recommend referring to the comprehensive [rStrava documentation](https://github.com/fawda123/rStrava)  and [this handy blog](https://padpadpadpad.github.io/post/animate-your-strava-activities-using-rstrava-and-gganimate/) by one of the creators.

This project uses functions within the rStrava package and [gganimate](https://github.com/thomasp85/gganimate)/[ggplot2](https://github.com/tidyverse/ggplot2) to animate rides sequentially, and incorporates some design features using [ggtext](https://github.com/wilkelab/ggtext) and [ggimage](https://github.com/GuangchuangYu/ggimage). 


### Getting started
- - -

There are a couple of set up steps, which take ~30-60 minutes:

**1. Strava account and API application** - _this allows you to generate an authentication token and pull your data from Strava_.

- If you do not have an account already, [set up a Strava account](https://www.strava.com/) and record some activities
- Navigate to [profile settings](https://www.strava.com/settings/profile) ➡ 'My API Application' ➡ 'Create an application'
- Note your **application name**, **client id**, and **client secret** as you will need these when running the script
- You will also need to know your **athlete id**, located at the end of your Strava URL.

**2. Google API key in Maps Elevation API** - _this allows you to generate longitude and latitude data, download maps for ggmap, and calculate elevation data if needed_.

- To create a project, click on the following [link](https://developers.google.com/maps/documentation/elevation/get-api-key) ➡ 'Credentials' ➡ 'Create project'
- After the project is created, click on 'Create Credentials' ➡ 'API key'
- Note your **API key** as you will need this when running the script
- Next, navigate to 'Library' in the left hand tab, and search for 'Maps Elevation API' in the API Library.
- Click 'Enable'.

### Kudos 👍
<div style="width: 50%">

![](animations/strava_anim.gif)

</div>

<div style="width: 60%">

![](animations/triathlon_anim.gif)

</div>


