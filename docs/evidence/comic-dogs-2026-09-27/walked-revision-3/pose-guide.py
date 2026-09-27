"""Build an annotated anatomical guide; colored lines are not candidate artwork.

Usage: uv run python pose-guide.py
"""
from pathlib import Path
import hashlib
from PIL import Image, ImageDraw

here = Path(__file__).resolve().parent
source = here.parent / 'crops/dog/dog_front_diagonal.png'
assert hashlib.sha256(source.read_bytes()).hexdigest() == 'fdf9035a3b400a2efa6c9831397fe7984833e74809f44cf18218cc20a5d0fa36'
image = Image.open(source).convert('RGBA')
result = Image.new('RGBA',(image.width+40,image.height+70),(238,235,228,255))
result.alpha_composite(image,(20,50))
d = ImageDraw.Draw(result)
d.text((5,5),'DESIRED B: visible thigh from SAME rear hip',fill='black')
d.text((5,20),'Green = near hind chain; red circle = fixed hip',fill='black')
chain = [(62,145),(91,178),(82,207),(108,231)]
points = [(x+20,y+50) for x,y in chain]
d.line(points,fill='#00a550',width=7)
for x,y in points:
    d.ellipse((x-4,y-4,x+4,y+4),fill='#00a550')
x,y=points[0]
d.ellipse((x-9,y-9,x+9,y+9),outline='#ec143b',width=3)
# The guide distinguishes the stationary haunch's root from the moving visible thigh.
contour=[(85,106),(72,119),(66,135),(66,146),(75,159),(91,178)]
d.line([(x+20,y+50) for x,y in contour],fill='#00a550',width=3)
result.resize((result.width*3,result.height*3),Image.Resampling.NEAREST).save(here/'front-thigh-guide.png')
