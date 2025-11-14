#!/usr/bin/env python3
"""
Generate PhoneBuddy app icon
Creates a modern icon representing two connected phones with remote control
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("Pillow (PIL) not installed. Install with: pip install Pillow")
    exit(1)

def create_icon(size):
    """Create icon at specified size"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors from app theme
    blue = (94, 92, 230)  # #5E5CE6
    light_blue = (142, 140, 255)  # #8E8CFF
    orange = (255, 138, 101)  # #FF8A65
    white = (255, 255, 255, 255)
    
    # Draw gradient background circle
    center = size // 2
    radius = int(size * 0.45)
    
    # Outer circle with gradient effect (blue to light blue)
    for i in range(radius, 0, -2):
        alpha = int(255 * (1 - i / radius * 0.3))
        color = tuple(c + int((255 - c) * (1 - i / radius) * 0.3) for c in blue)
        draw.ellipse([center - i, center - i, center + i, center + i], 
                    fill=(*color, alpha))
    
    # Draw two phone outlines (left and right)
    phone_width = int(size * 0.12)
    phone_height = int(size * 0.25)
    phone_y = center - phone_height // 2
    
    # Left phone
    left_x = center - int(size * 0.25)
    draw.rounded_rectangle([left_x - phone_width//2, phone_y, 
                           left_x + phone_width//2, phone_y + phone_height],
                          radius=phone_width//4, fill=white, outline=blue, width=2)
    # Phone screen
    draw.rectangle([left_x - phone_width//2 + 2, phone_y + 3,
                   left_x + phone_width//2 - 2, phone_y + phone_height - 8],
                  fill=blue)
    
    # Right phone
    right_x = center + int(size * 0.25)
    draw.rounded_rectangle([right_x - phone_width//2, phone_y,
                           right_x + phone_width//2, phone_y + phone_height],
                          radius=phone_width//4, fill=white, outline=orange, width=2)
    # Phone screen
    draw.rectangle([right_x - phone_width//2 + 2, phone_y + 3,
                   right_x + phone_width//2 - 2, phone_y + phone_height - 8],
                  fill=orange)
    
    # Connection line between phones
    draw.line([left_x + phone_width//2, center, right_x - phone_width//2, center],
             fill=light_blue, width=max(2, size // 64))
    
    # Remote control symbol in center (circle with play icon)
    control_size = int(size * 0.15)
    draw.ellipse([center - control_size//2, center - control_size//2,
                  center + control_size//2, center + control_size//2],
                fill=white, outline=blue, width=max(2, size // 128))
    
    # Play triangle inside control circle
    triangle_size = int(control_size * 0.4)
    triangle_points = [
        (center - triangle_size//3, center - triangle_size//2),
        (center - triangle_size//3, center + triangle_size//2),
        (center + triangle_size//2, center)
    ]
    draw.polygon(triangle_points, fill=blue)
    
    return img

def main():
    """Generate all required icon sizes"""
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    base_dir = 'telepathy_flutter_app/android/app/src/main/res'
    icon_name = 'ic_launcher.png'
    
    print("Generating PhoneBuddy icons...")
    
    for folder, size in sizes.items():
        icon_path = os.path.join(base_dir, folder, icon_name)
        os.makedirs(os.path.dirname(icon_path), exist_ok=True)
        
        icon = create_icon(size)
        icon.save(icon_path, 'PNG')
        print(f"✓ Created {icon_path} ({size}x{size})")
    
    # Also create a 512x512 version for app stores/documentation
    large_icon = create_icon(512)
    large_icon.save('phonebuddy-icon-512.png', 'PNG')
    print(f"✓ Created phonebuddy-icon-512.png (512x512) for documentation")
    
    print("\n✓ All icons generated successfully!")

if __name__ == '__main__':
    main()

