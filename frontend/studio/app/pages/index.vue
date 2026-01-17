<script setup lang="ts">
import { usePostsStore } from '~/stores/posts'

const postsStore = usePostsStore()

definePageMeta({
  layout: 'default',
})

const statusOptions = [
  { value: 'all', label: '전체' },
  { value: 'draft', label: '임시저장' },
  { value: 'published', label: '게시됨' },
  { value: 'archived', label: '보관됨' },
]
</script>

<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-3xl font-bold tracking-tight">게시글 관리</h2>
        <p class="text-muted-foreground mt-2">
          블로그 컨텐츠를 생성하고 관리하세요
        </p>
      </div>
      <Button as="a" href="/editor/new">
        <Icon name="lucide:plus" class="w-4 h-4 mr-2" />
        새 글 작성
      </Button>
    </div>

    <!-- Stats Cards -->
    <div class="grid gap-4 md:grid-cols-3">
      <Card>
        <CardHeader class="flex flex-row items-center justify-between pb-2">
          <CardTitle class="text-sm font-medium">전체 게시글</CardTitle>
          <Icon name="lucide:file-text" class="w-4 h-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{{ postsStore.posts.length }}</div>
          <p class="text-xs text-muted-foreground mt-1">
            총 게시글 수
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader class="flex flex-row items-center justify-between pb-2">
          <CardTitle class="text-sm font-medium">게시됨</CardTitle>
          <Icon name="lucide:check-circle" class="w-4 h-4 text-green-500" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{{ postsStore.publishedPosts.length }}</div>
          <p class="text-xs text-muted-foreground mt-1">
            공개된 게시글
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader class="flex flex-row items-center justify-between pb-2">
          <CardTitle class="text-sm font-medium">임시저장</CardTitle>
          <Icon name="lucide:edit" class="w-4 h-4 text-yellow-500" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{{ postsStore.draftPosts.length }}</div>
          <p class="text-xs text-muted-foreground mt-1">
            작성 중인 게시글
          </p>
        </CardContent>
      </Card>
    </div>

    <!-- Filters -->
    <Card>
      <CardHeader>
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <Input 
              v-model="postsStore.searchQuery"
              type="search"
              placeholder="제목, 내용, 태그로 검색..."
              class="w-full"
            >
              <template #prefix>
                <Icon name="lucide:search" class="w-4 h-4 text-muted-foreground" />
              </template>
            </Input>
          </div>
          <div class="flex gap-2">
            <Button
              v-for="option in statusOptions"
              :key="option.value"
              :variant="postsStore.statusFilter === option.value ? 'default' : 'outline'"
              size="sm"
              @click="postsStore.setStatusFilter(option.value as any)"
            >
              {{ option.label }}
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <PostList />
      </CardContent>
    </Card>
  </div>
</template>
