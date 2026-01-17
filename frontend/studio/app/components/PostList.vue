<script setup lang="ts">
import { usePostsStore } from '~/stores/posts'
import type { Post } from '~/stores/posts'

const postsStore = usePostsStore()

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

const handleEdit = (post: Post) => {
  navigateTo(`/editor/${post.id}`)
}

const handleDelete = (post: Post) => {
  if (confirm(`정말로 "${post.title}"을 삭제하시겠습니까?`)) {
    postsStore.deletePost(post.id)
  }
}

const handleTogglePublish = (post: Post) => {
  if (post.status === 'published') {
    postsStore.unpublishPost(post.id)
  } else {
    postsStore.publishPost(post.id)
  }
}
</script>

<template>
  <div class="space-y-4">
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead class="w-[40%]">제목</TableHead>
          <TableHead>상태</TableHead>
          <TableHead>카테고리</TableHead>
          <TableHead>수정일</TableHead>
          <TableHead class="text-right">작업</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        <TableRow 
          v-for="post in postsStore.filteredPosts" 
          :key="post.id"
          class="cursor-pointer"
        >
          <TableCell class="font-medium">
            <div>
              <div class="font-semibold">{{ post.title }}</div>
              <div v-if="post.excerpt" class="text-sm text-muted-foreground mt-1">
                {{ post.excerpt }}
              </div>
              <div v-if="post.tags && post.tags.length > 0" class="flex gap-1 mt-2">
                <Badge 
                  v-for="tag in post.tags.slice(0, 3)" 
                  :key="tag" 
                  variant="outline"
                  class="text-xs"
                >
                  {{ tag }}
                </Badge>
              </div>
            </div>
          </TableCell>
          <TableCell>
            <StatusBadge :status="post.status" />
          </TableCell>
          <TableCell>
            <span class="text-sm">{{ post.category || '-' }}</span>
          </TableCell>
          <TableCell>
            <span class="text-sm text-muted-foreground">
              {{ formatDate(post.updatedAt) }}
            </span>
          </TableCell>
          <TableCell class="text-right">
            <div class="flex justify-end gap-2">
              <Button 
                variant="ghost" 
                size="icon"
                @click.stop="handleEdit(post)"
                title="수정"
              >
                <Icon name="lucide:pencil" class="w-4 h-4" />
              </Button>
              <Button 
                variant="ghost" 
                size="icon"
                @click.stop="handleTogglePublish(post)"
                :title="post.status === 'published' ? '게시 취소' : '게시'"
              >
                <Icon 
                  :name="post.status === 'published' ? 'lucide:eye-off' : 'lucide:eye'" 
                  class="w-4 h-4" 
                />
              </Button>
              <Button 
                variant="ghost" 
                size="icon"
                @click.stop="handleDelete(post)"
                title="삭제"
              >
                <Icon name="lucide:trash-2" class="w-4 h-4 text-destructive" />
              </Button>
            </div>
          </TableCell>
        </TableRow>
        <TableRow v-if="postsStore.filteredPosts.length === 0">
          <TableCell colspan="5" class="text-center py-8 text-muted-foreground">
            게시글이 없습니다.
          </TableCell>
        </TableRow>
      </TableBody>
    </Table>
  </div>
</template>
