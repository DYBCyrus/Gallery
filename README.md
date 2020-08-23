# Gallery
# Inspiration
Here is the formula we came to: Augmented Reality Portals + Instagram = Gallery!

# What it does
Users can design and explore personal galleries hiding in a "portal" using this APP. A gallery here is an AR-view house which allows its owner to customize its inner appearance - background and furnitures, and upload their pictures, or even videos to this gallery. A user could have multiply galleries in multiply location. When a gallery is created, this APP could record its geolocation, and therefore allows other users to explore this created gallery where they are in that location.

# How we built it
For front-end, we mainly use arkit in swift to construct whole ar scene and the portal. We first create portal room via Scene Graph in arkit, and place few 3D models in the room. On every wall, there are windows or photo frames. User can hit on the frames to upload photos or videos. And for back-end, we use firebase, geo location and database to enable login and store portal. We first have a login page, and then a map indicating surrounding portals. User can hit on the stickers to look for others’ portal, and they can also create their own portal at their locations.

# Challenges we ran into
Firebase is really hard to use!

# Accomplishments that we're proud of
We can bring portals to the real world! It is just amazing to see that a portal suddenly appears in front of us and we are able to walk into the room and see it with different angles. We are also proud of the completeness of the app.

# What we learned
Firebase fundamentals. Google Maps API implementation. Real time database system. UI/UX designs and much more!

# What's next for Gallery
There are countless possibilities to Gallery. We are planning to add more social features to Gallery such as comment system, like system, following system, more geolocation interactions such as people can explore portals in the city, or a specific range of area, and more flexible portals that allow users to customizing the room, changing the background, uploading 3D models, posting Gifs or more videos, and etc.

We can wait for the grow of Gallery!

# Demo
Please see the [demo](https://youtu.be/lVPNWFRuY6A) here.
