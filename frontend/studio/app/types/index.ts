export type PostStatus = 'draft' | 'published' | 'archived'

export interface Post {
  id: string
  title: string
  slug: string
  content: string
  excerpt?: string
  status: PostStatus
  category?: string
  tags?: string[]
  createdAt: string
  updatedAt: string
  publishedAt?: string
}

export interface PostFilters {
  status: 'all' | PostStatus
  search: string
}
