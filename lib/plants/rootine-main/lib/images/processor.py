from PIL import Image
import os

# Directory containing the images
input_directory = "."
output_directory = "./processed_images"

# Ensure the output directory exists
os.makedirs(output_directory, exist_ok=True)

# Process each image
for i in range(1, 10):  # Img1 to Img9
    input_file = f"Img{i}.jpg"
    output_file = f"{output_directory}/Img{i}.png"

    try:
        # Open the image
        with Image.open(input_file) as img:
            # Convert to RGBA to handle transparency
            img = img.convert("RGBA")
            data = img.getdata()

            # Replace white background with transparency
            new_data = []
            for item in data:
                # Check if the pixel is white (255, 255, 255)
                if item[:3] == (255, 255, 255):
                    # Replace with transparent pixel
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append(item)

            img.putdata(new_data)

            # Trim the image to content
            img = img.crop(img.getbbox())

            # Save the processed image as PNG
            img.save(output_file, "PNG")
            print(f"Processed {input_file} -> {output_file}")

    except FileNotFoundError:
        print(f"File {input_file} not found. Skipping.")