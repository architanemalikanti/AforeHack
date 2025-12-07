# Profile Layout System - README

## Overview
This system creates a dynamic, visually interesting profile page where posts are displayed based on the number of images they contain (1-10). Each image count has its own unique layout, and posts are cached locally to avoid repeated API calls.

## Files Created

### 1. PostLayoutView.swift
Contains all the layout structs for different image counts:
- **SingleImageLayout**: 1 large centered image
- **TwoImageLayout**: 2 images side by side
- **ThreeImageLayout**: 1 large on top, 2 smaller below
- **FourImageLayout**: 2x2 grid
- **FiveImageLayout**: 2 on top, 3 on bottom
- **SixImageLayout**: 3x2 grid
- **SevenImageLayout**: 3 + 4 layout
- **EightImageLayout**: 4x2 grid
- **NineImageLayout**: 3x3 grid
- **TenImageLayout**: 5x2 layout

Each layout automatically:
- Loads images from Firebase URLs using AsyncImage
- Shows loading spinner while images load
- Displays caption below images in DMSans-Regular 14pt
- Handles failed image loads gracefully

### 2. PostCacheManager.swift
Handles all caching logic:
- `savePosts()` - Cache posts to UserDefaults
- `loadPosts()` - Load cached posts
- `clearCache()` - Clear cache when user creates new post
- `addNewPost()` - Add a single new post to existing cache

Cache key format: `user_posts_{user_id}`

### 3. UserProfileView.swift
The main profile view that displays all posts:
- Shows username, name, and post count
- Loads posts from cache first (instant!)
- Only calls API if cache doesn't exist
- Automatically caches API responses
- Displays posts using PostLayoutView

## Data Models

### UserPost
```swift
struct UserPost: Codable, Identifiable {
    let post_id: String
    let caption: String
    let post_media: [String]  // Array of Firebase URLs
    let created_at: String
}
```

### UserPostsResponse (API Response)
```swift
struct UserPostsResponse: Codable {
    let status: String
    let user_id: String
    let username: String
    let name: String
    let posts: [UserPost]
}
```

## Backend API Endpoint Needed

You'll need to create this route in your FastAPI backend:

```python
@app.get("/posts/user/{user_id}")
async def get_user_posts(user_id: str):
    # Fetch all posts for this user from database
    # Order by created_at DESC (most recent first)

    return {
        "status": "success",
        "user_id": user_id,
        "username": "archita",  # From user table
        "name": "Archita",      # From user table
        "posts": [
            {
                "post_id": "uuid-1",
                "caption": "christmas in sf hitting different ✨",
                "post_media": [
                    "https://firebase.storage/.../image1.jpg",
                    "https://firebase.storage/.../image2.jpg"
                ],
                "created_at": "2025-11-25T00:02:57"
            }
            # ... more posts
        ]
    }
```

## How Caching Works

### First Time User Opens Profile:
1. `UserProfileView.onAppear` calls `loadPosts()`
2. `PostCacheManager.loadPosts()` returns `nil` (no cache)
3. Makes API call to `/posts/user/{user_id}`
4. Receives posts and saves to cache via `PostCacheManager.savePosts()`
5. Displays posts using appropriate layouts

### Second Time (and onwards):
1. `UserProfileView.onAppear` calls `loadPosts()`
2. `PostCacheManager.loadPosts()` returns cached posts instantly
3. **No API call made** - displays immediately
4. Super fast loading!

### When User Creates New Post:
After post is created, call:
```swift
PostCacheManager.shared.clearCache(for: userID)
```
Then the next time profile loads, it will fetch fresh data from API.

## How to Use

### Option 1: Add to VogueWelcome
Replace the current profile button navigation with:
```swift
Button(action: {
    navigateToProfile = true
}) {
    Text("View Profile")
}

// In ZStack:
if navigateToProfile {
    UserProfileView(userID: userID)
        .transition(.opacity)
}
```

### Option 2: Add to MainTabView
Add a profile tab that shows `UserProfileView`:
```swift
case .profile:
    if let userID = userID {
        UserProfileView(userID: userID)
    }
```

### Option 3: Standalone Usage
```swift
UserProfileView(userID: "user-uuid-here")
```

## Customizing Layouts

Each layout struct can be customized independently. For example, to change the 4-image layout:

1. Open `PostLayoutView.swift`
2. Find `FourImageLayout`
3. Modify the grid arrangement, spacing, or sizes
4. Change font styles, colors, or add animations

Example customizations:
- Change image sizes
- Adjust corner radius
- Modify spacing between images
- Add overlay effects
- Change caption styling
- Add timestamps or other metadata

## Performance Notes

- **AsyncImage** handles image loading and caching automatically
- **UserDefaults** is fine for caching since posts are JSON (not heavy)
- For 100+ posts, consider using CoreData or SQLite instead
- Images are lazy-loaded as user scrolls
- Cache never expires (only cleared manually when new post created)

## Future Enhancements

### 1. Pull to Refresh
Add SwiftUI's refreshable modifier:
```swift
.refreshable {
    PostCacheManager.shared.clearCache(for: userID)
    loadPosts()
}
```

### 2. Add Timestamps
Show how long ago post was created:
```swift
Text(timeAgo(from: post.created_at))
    .font(.custom("DMSans-Regular", size: 12))
    .foregroundColor(.white.opacity(0.5))
```

### 3. Tap to View Full Screen
Add tap gesture to images to open full screen viewer

### 4. Like/Comment Integration
Add overlay badges showing like/comment counts on each post

### 5. Pagination
If user has 100+ posts, add pagination:
```swift
func fetchUserPosts(userID: String, limit: Int = 20, offset: Int = 0)
```

## Summary

✅ **Dynamic layouts** based on image count (1-10)
✅ **Smart caching** - only fetches once, then instant loads
✅ **Firebase image URLs** - no base64 bloat
✅ **Graceful loading** - spinners and error states
✅ **Easy to customize** - each layout is independent
✅ **No boring grids** - unique layouts for each post

The profile will look creative and load instantly after the first visit! 🎉
