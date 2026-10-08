# Playtest olive-toad — The trailer is linked from the README

2026-10-08.

## #627 — Show the trailer in the repository README

The player asks how to present the approved trailer in the repository:

> I want to have the trailer on the readme in the repo -- should I (a) upload it to youtube and we do an embed (does that even work?) or (b) we upload it to the repo in a different folder and embed?

The assistant recommends a GitHub attachment for an inline README video, keeping the MP4
outside Git history. The player reports the upload limit, considers alternatives, then supplies
the published YouTube URL and requests implementation and a patch release:

> This video is too big.
>  with a file size less than 10MB.
> -- it's fine we can commit the video
>
> or I upload to youtube
>
> https://youtu.be/88nfOmjEcHc -- here is the video embed it
>
> push merge and release the patch
