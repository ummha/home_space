import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface Post {
  id: string
  title: string
  slug: string
  content: string
  excerpt?: string
  status: 'draft' | 'published' | 'archived'
  category?: string
  tags?: string[]
  createdAt: string
  updatedAt: string
  publishedAt?: string
}

export const usePostsStore = defineStore('posts', () => {
  const posts = ref<Post[]>([
    {
      id: '1',
      title: 'Getting Started with Nuxt 4',
      slug: 'getting-started-nuxt-4',
      content: '# Getting Started with Nuxt 4\n\nNuxt 4 brings exciting new features...',
      excerpt: 'Learn about the new features in Nuxt 4',
      status: 'published',
      category: 'Tutorial',
      tags: ['nuxt', 'vue', 'web development'],
      createdAt: '2025-01-15T10:00:00Z',
      updatedAt: '2025-01-15T10:00:00Z',
      publishedAt: '2025-01-15T10:00:00Z',
    },
    {
      id: '2',
      title: 'Building Admin Consoles with Vue',
      slug: 'building-admin-consoles-vue',
      content: '# Building Admin Consoles\n\nCreating a modern admin console...',
      excerpt: 'Best practices for admin consoles',
      status: 'draft',
      category: 'Development',
      tags: ['vue', 'admin', 'ui'],
      createdAt: '2025-01-16T14:30:00Z',
      updatedAt: '2025-01-17T09:00:00Z',
    },
    {
      id: '3',
      title: 'Markdown Editing Best Practices',
      slug: 'markdown-editing-best-practices',
      content: '# Markdown Editing\n\nMarkdown is a lightweight markup language...',
      excerpt: 'Tips for effective markdown writing',
      status: 'published',
      category: 'Writing',
      tags: ['markdown', 'writing', 'productivity'],
      createdAt: '2025-01-14T08:00:00Z',
      updatedAt: '2025-01-14T08:00:00Z',
      publishedAt: '2025-01-14T08:00:00Z',
    },
  ])

  const currentPost = ref<Post | null>(null)
  const searchQuery = ref('')
  const statusFilter = ref<'all' | 'draft' | 'published' | 'archived'>('all')

  const filteredPosts = computed(() => {
    let filtered = posts.value

    // Filter by status
    if (statusFilter.value !== 'all') {
      filtered = filtered.filter(post => post.status === statusFilter.value)
    }

    // Filter by search query
    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      filtered = filtered.filter(post =>
        post.title.toLowerCase().includes(query) ||
        post.content.toLowerCase().includes(query) ||
        post.tags?.some(tag => tag.toLowerCase().includes(query))
      )
    }

    return filtered.sort((a, b) => 
      new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
    )
  })

  const publishedPosts = computed(() => 
    posts.value.filter(post => post.status === 'published')
  )

  const draftPosts = computed(() => 
    posts.value.filter(post => post.status === 'draft')
  )

  function getPostById(id: string): Post | undefined {
    return posts.value.find(post => post.id === id)
  }

  function createPost(postData: Omit<Post, 'id' | 'createdAt' | 'updatedAt'>): Post {
    const newPost: Post = {
      ...postData,
      id: Date.now().toString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
    posts.value.unshift(newPost)
    return newPost
  }

  function updatePost(id: string, updates: Partial<Post>): void {
    const index = posts.value.findIndex(post => post.id === id)
    if (index !== -1) {
      posts.value[index] = {
        ...posts.value[index],
        ...updates,
        updatedAt: new Date().toISOString(),
      }
    }
  }

  function deletePost(id: string): void {
    const index = posts.value.findIndex(post => post.id === id)
    if (index !== -1) {
      posts.value.splice(index, 1)
    }
  }

  function publishPost(id: string): void {
    updatePost(id, {
      status: 'published',
      publishedAt: new Date().toISOString(),
    })
  }

  function unpublishPost(id: string): void {
    updatePost(id, {
      status: 'draft',
    })
  }

  function setCurrentPost(post: Post | null): void {
    currentPost.value = post
  }

  function setSearchQuery(query: string): void {
    searchQuery.value = query
  }

  function setStatusFilter(status: 'all' | 'draft' | 'published' | 'archived'): void {
    statusFilter.value = status
  }

  return {
    posts,
    currentPost,
    searchQuery,
    statusFilter,
    filteredPosts,
    publishedPosts,
    draftPosts,
    getPostById,
    createPost,
    updatePost,
    deletePost,
    publishPost,
    unpublishPost,
    setCurrentPost,
    setSearchQuery,
    setStatusFilter,
  }
})
