from django.urls import path
from .views import blog_list

urlpatterns = [
    path('list/', blog_list, name='blog_list'),
]