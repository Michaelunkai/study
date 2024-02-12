




# modules
import os  # Import os module for environment variables
import flet
from flet import Page, CrossAxisAlignment, MainAxisAlignment, UserControl, Container, Row, Text, Divider, Icon, TextField, Alignment, RadialGradient, ClipBehavior, border

from dotenv import load_dotenv

load_dotenv()

APIKEY = os.getenv("APIKEY")

# start with the app title
class AppTitle(UserControl):
    def __init__(self):
        super().__init__()

    def InputContainer(self, width: int):
        return Container(
            width=width,
            height=40,
            bgcolor="#ffffff10",  # Changed "white10" to "#ffffff10"
            border_radius=8,
            padding=8,
            content=Row(
                spacing=10,
                vertical_alignment=CrossAxisAlignment.CENTER,
                controls=[
                    Icon(name="icons.SEARCH_ROUNDED", size=17, opacity=0.8),  # Added quotes around "icons.SEARCH_ROUNDED"
                    TextField(
                        border_color="transparent",
                        height=20,
                        text_size=14,
                        cursor_color="white",
                        content_padding=0,
                        cursor_width=1,
                        color="white",
                        hint_text="Search",
                    ),
                ],
            ),
        )

    def build(self):
        return Container(
            padding=10,  # Fixed typo "padding.obly" to "padding"
            content=Column(
                horizontal_alignment=CrossAxisAlignment.CENTER,
                controls=[
                    Text(
                        "IMDb Movies & Shows",
                        size=15,
                        weight="bold"
                    ),
                    Divider(height=5, color="transparent"),
                    self.InputContainer(280),
                    Divider(height=20, color="#ffffff10")  # Changed "white10" to "#ffffff10"
                ],
            ),
        )


# coming soon movies
class ComingSoon(UserControl):
    def __init__(self):
        super().__init__()

    def build(self):
        return Container(
            width=280,
            height=240,
            content=Column(
                controls=[
                    Row(
                        controls=[
                            Text(
                                "Coming Soon",
                                size=14,
                            )
                        ]
                    ),
                    self.ComingSoonTitle(),
                ],
            ),
        )


def main(page: Page):
    page.horizontal_alignment = CrossAxisAlignment.CENTER
    page.vertical_alignment = MainAxisAlignment.CENTER
    page.bgcolor = "#ffffff10"

    # main container
    _main_ = Container(
        width=290,
        height=600,
        gradient=RadialGradient(
            center=Alignment(-0.5, -0.8),
            radius=3,
            colors=[
                "#33354a",
                "#2c2e3f",
                "#3d3f54",
                "#2e2f41",
                "#343653",
                "#282a3d",
                "#323447",
                "#2f3145",
                "#373855",
                "#2a2c40",
                "#31334a",
                "#000000",  # Added missing hex code symbol "#"
            ],
        ),
        border_radius=30,
        border=border.all(2, "#000000"),
        padding=10,
        clip_behavior=ClipBehavior.HARD_EDGE,
        content=Column(
            scroll='none',
            horizontal_alignment=CrossAxisAlignment.CENTER,
            controls=[
                AppTitle(),
                Container(
                    expand=True,
                    padding=10,
                    content=Column(
                        scroll="hidden",
                        controls=[
                            ComingSoon(),
                            Divider(height=10, color="#ffffff10")  # Changed "white10" to "#ffffff10"
                        ],
                    ),
                ),
            ],
        ),
    )
    page.add(_main_)
    page.update()

if __name__ == "__main__":
    flet.app(target=main)
