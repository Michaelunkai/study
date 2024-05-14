#blog/views.py
from django.shortcuts import render
from django.http import HttpResponse
from .models import BlogPost
# Create your views here.
def blog_list(request):
    posts = BlogPost.objects.all()
    return render(request, 'blog/blog_list.html', {'posts': posts})