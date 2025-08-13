### Dislike Tiktok Web
```
// Recursive function to like and navigate through videos
function likeAndNextVideo() {
  try {
    // Step 1: Select the like button dynamically
    const likeButton = document.querySelector('button.css-1ncfmqs-ButtonActionItem.e1hk3hf90');

    // Step 2: Check if the button is pressed (liked)
    if (likeButton && likeButton.getAttribute('aria-pressed') === 'true') {
      likeButton.click(); // Unlike the video
    }

    // Step 3: Click the next video button
    const nextVideoButton = document.querySelector('button[data-e2e="arrow-right"]');
    if (nextVideoButton) {
      nextVideoButton.click(); // Load the next video

      // Add a delay of 5 seconds before loading the next video
      setTimeout(likeAndNextVideo, 5000); // 5000ms = 5 seconds
    } else {
      // If no next video button is found, stop the script
      return;
    }
  } catch (error) {
    console.error('Error occurred:', error);
  }
}

// Start the recursive function
likeAndNextVideo();
```
