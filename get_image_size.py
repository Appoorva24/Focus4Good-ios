from PIL import Image
try:
    with Image.open("/Users/gu/Desktop/Focus4Good-ios/Focus4Good/Focus4Good/Assets.xcassets/plannercard.imageset/Gemini_Generated_Image_937le1937le1937l (1).png") as img:
        print(f"Size: {img.size}")
except Exception as e:
    print(f"Error: {e}")
